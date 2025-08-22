;; HealthChain: Decentralized Medical Research Contribution Platform
;; Version: 1.0.0

(define-data-var research-director principal tx-sender)
(define-data-var data-repository uint u0)
(define-data-var research-token-rate uint u75) ;; research tokens per contribution cycle
(define-data-var last-token-distribution uint u0) ;; last block when tokens were distributed

(define-map researcher-contributions principal uint)

;; Helper function to ensure only the research director can perform certain actions
(define-private (is-director (caller principal))
  (begin
    (asserts! (is-eq caller (var-get research-director)) (err u300))
    (ok true)))

;; Initialize the medical research platform
(define-public (launch-research-network (director principal))
  (begin
    (asserts! (is-none (map-get? researcher-contributions director)) (err u301))
    (var-set research-director director)
    (ok "HealthChain research network launched")))

;; Submit research data contribution
(define-public (submit-research-data (datasets uint))
  (begin
    (asserts! (> datasets u0) (err u302))
    (let ((current-contributions (default-to u0 (map-get? researcher-contributions tx-sender))))
      (map-set researcher-contributions tx-sender (+ current-contributions datasets))
      (var-set data-repository (+ (var-get data-repository) datasets))
      (ok (+ current-contributions datasets)))))

;; Distribute research tokens for all contributors
(define-public (distribute-research-tokens)
  (begin
    (try! (is-director tx-sender))
    (let ((current-block stacks-block-height)
          (previous-distribution (var-get last-token-distribution)))
      (asserts! (> current-block previous-distribution) (err u303))
      ;; Calculate tokens based on blocks elapsed
      (let ((elapsed (- current-block previous-distribution))
            (total-tokens (* elapsed (var-get research-token-rate))))
        (var-set last-token-distribution current-block)
        (var-set data-repository (+ (var-get data-repository) total-tokens))
        (ok total-tokens)))))

;; Claim research rewards and withdraw contributions
(define-public (claim-research-rewards)
  (begin
    (let ((researcher-data (default-to u0 (map-get? researcher-contributions tx-sender))))
      (asserts! (> researcher-data u0) (err u304))
      (let ((total-repository (var-get data-repository))
            (new-tokens (* (var-get research-token-rate) (- stacks-block-height (var-get last-token-distribution))))
            (contribution-ratio (/ (* researcher-data u100000) total-repository)))
        ;; Calculate rewards based on contribution ratio
        (let ((reward-amount (/ (* contribution-ratio new-tokens) u100000)))
          (map-delete researcher-contributions tx-sender)
          (var-set data-repository (- (var-get data-repository) researcher-data))
          (ok (+ researcher-data reward-amount)))))))

;; Read-only functions
(define-read-only (get-researcher-contributions (researcher principal))
  (default-to u0 (map-get? researcher-contributions researcher)))

(define-read-only (get-research-stats)
  {
    director: (var-get research-director),
    total-repository: (var-get data-repository),
    token-rate: (var-get research-token-rate),
    last-distribution: (var-get last-token-distribution)
  })

(define-read-only (get-data-repository)
  (var-get data-repository))