;; Service Provider Verification Contract
;; Manages verification and registration of telecommunications service providers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_EXISTS (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Provider status constants
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structures
(define-map providers
  { provider-id: principal }
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    status: uint,
    verification-date: uint,
    services: (list 10 (string-ascii 50))
  }
)

(define-map provider-metrics
  { provider-id: principal }
  {
    total-customers: uint,
    uptime-percentage: uint,
    complaint-count: uint,
    rating: uint
  }
)

(define-data-var total-providers uint u0)

;; Register a new service provider
(define-public (register-provider (name (string-ascii 100)) (license-number (string-ascii 50)) (services (list 10 (string-ascii 50))))
  (let ((provider-id tx-sender))
    (asserts! (is-none (map-get? providers { provider-id: provider-id })) ERR_PROVIDER_EXISTS)
    (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        license-number: license-number,
        status: STATUS_PENDING,
        verification-date: block-height,
        services: services
      }
    )
    (map-set provider-metrics
      { provider-id: provider-id }
      {
        total-customers: u0,
        uptime-percentage: u100,
        complaint-count: u0,
        rating: u5
      }
    )
    (var-set total-providers (+ (var-get total-providers) u1))
    (ok provider-id)
  )
)

;; Verify a service provider (admin only)
(define-public (verify-provider (provider-id principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { status: STATUS_VERIFIED, verification-date: block-height })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Update provider status
(define-public (update-provider-status (provider-id principal) (new-status uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-status STATUS_REVOKED) ERR_INVALID_STATUS)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { status: new-status })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Get provider information
(define-read-only (get-provider (provider-id principal))
  (map-get? providers { provider-id: provider-id })
)

;; Get provider metrics
(define-read-only (get-provider-metrics (provider-id principal))
  (map-get? provider-metrics { provider-id: provider-id })
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider-id principal))
  (match (map-get? providers { provider-id: provider-id })
    provider-data
    (is-eq (get status provider-data) STATUS_VERIFIED)
    false
  )
)

;; Get total number of providers
(define-read-only (get-total-providers)
  (var-get total-providers)
)
