;; PropertyLock Contract
;; Real estate listing subscription platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data Maps
(define-map properties 
    { property-id: uint }
    {
        owner: principal,
        price: uint,
        status: (string-ascii 20),
        document-hash: (string-ascii 64),
        verified: bool
    }
)

(define-map brokers
    { broker: principal }
    {
        access-level: uint,
        active: bool
    }
)

(define-map transactions
    { tx-id: uint }
    {
        property-id: uint,
        seller: principal,
        buyer: principal,
        price: uint,
        timestamp: uint
    }
)

;; Public Functions
(define-public (list-property (property-id uint) (price uint) (document-hash (string-ascii 64)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set properties
            { property-id: property-id }
            {
                owner: tx-sender,
                price: price,
                status: "available",
                document-hash: document-hash,
                verified: false
            }
        ))
    )
)

(define-public (verify-property (property-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set properties
            { property-id: property-id }
            (merge (unwrap-panic (get-property property-id))
                { verified: true })
        ))
    )
)

(define-public (register-broker (broker principal) (access-level uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set brokers
            { broker: broker }
            {
                access-level: access-level,
                active: true
            }
        ))
    )
)

;; Read Only Functions
(define-read-only (get-property (property-id uint))
    (map-get? properties { property-id: property-id })
)

(define-read-only (get-broker (broker principal))
    (map-get? brokers { broker: broker })
)

(define-read-only (is-verified-broker (broker principal))
    (match (get-broker broker)
        broker-data (ok (get active broker-data))
        err-not-found
    )
)
