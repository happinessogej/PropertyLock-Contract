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

(define-read-only (get-bid (property-id uint) (bidder principal))
    (map-get? property-bids { property-id: property-id, bidder: bidder })
)

(define-read-only (is-property-owner (property-id uint) (owner principal))
    (match (get-property property-id)
        property (is-eq (get owner property) owner)
        false
    )
)



;; Add to Data Maps
(define-map property-bids
    { property-id: uint, bidder: principal }
    {
        bid-amount: uint,
        timestamp: uint,
        status: (string-ascii 10)
    }
)

(define-public (place-bid (property-id uint) (bid-amount uint))
    (begin
        (asserts! (> bid-amount u0) (err u103))
        (ok (map-set property-bids
            { property-id: property-id, bidder: tx-sender }
            {
                bid-amount: bid-amount,
                timestamp: stacks-block-height,
                status: "pending"
            }
        ))
    )
)



(define-public (accept-bid (property-id uint) (bidder principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set property-bids
            { property-id: property-id, bidder: bidder }
            (merge (unwrap-panic (get-bid property-id bidder))
                { status: "accepted" })
        ))
    )
)


(define-public (reject-bid (property-id uint) (bidder principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set property-bids
            { property-id: property-id, bidder: bidder }
            (merge (unwrap-panic (get-bid property-id bidder))
                { status: "rejected" })
        ))
    )
)


(define-public (close-bid (property-id uint) (bidder principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set property-bids
            { property-id: property-id, bidder: bidder }
            (merge (unwrap-panic (get-bid property-id bidder))
                { status: "closed" })
        ))
    )
)


(define-public (transfer-property (property-id uint) (buyer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (let ((property (unwrap-panic (get-property property-id))))
            (ok (map-set properties
                { property-id: property-id }
                (merge property
                    { owner: buyer, status: "sold" })
            ))
        )
    )
)

(define-map property-reviews
    { property-id: uint, reviewer: principal }
    {
        rating: uint,
        comment: (string-ascii 200),
        timestamp: uint
    }
)

(define-public (add-review (property-id uint) (rating uint) (comment (string-ascii 200)))
    (begin
        (asserts! (<= rating u5) (err u104))
        (ok (map-set property-reviews
            { property-id: property-id, reviewer: tx-sender }
            {
                rating: rating,
                comment: comment,
                timestamp: stacks-block-height
            }
        ))
    )
)



(define-map maintenance-records
    { property-id: uint, record-id: uint }
    {
        description: (string-ascii 200),
        cost: uint,
        date: uint,
        contractor: principal
    }
)

(define-public (add-maintenance-record 
    (property-id uint) 
    (record-id uint)
    (description (string-ascii 200))
    (cost uint))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u105))
        (ok (map-set maintenance-records
            { property-id: property-id, record-id: record-id }
            {
                description: description,
                cost: cost,
                date: stacks-block-height,
                contractor: tx-sender
            }
        ))
    )
)


(define-public (update-maintenance-record 
    (property-id uint) 
    (record-id uint)
    (description (string-ascii 200))
    (cost uint))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u105))
        (ok (map-set maintenance-records
            { property-id: property-id, record-id: record-id }
            {
                description: description,
                cost: cost,
                date: stacks-block-height,
                contractor: tx-sender
            }
        ))
    )
)



(define-map escrow-accounts
    { transaction-id: uint }
    {
        amount: uint,
        buyer: principal,
        seller: principal,
        status: (string-ascii 20)
    }
)

(define-public (create-escrow (transaction-id uint) (amount uint))
    (begin
        (asserts! (> amount u0) (err u107))
        (ok (map-set escrow-accounts
            { transaction-id: transaction-id }
            {
                amount: amount,
                buyer: tx-sender,
                seller: contract-owner,
                status: "pending"
            }
        ))
    )
)


(define-map rental-agreements
    { property-id: uint, tenant: principal }
    {
        rent-amount: uint,
        start-date: uint,
        end-date: uint,
        status: (string-ascii 20)
    }
)

(define-public (create-rental-agreement 
    (property-id uint)
    (rent-amount uint)
    (duration uint))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u108))
        (ok (map-set rental-agreements
            { property-id: property-id, tenant: tx-sender }
            {
                rent-amount: rent-amount,
                start-date: stacks-block-height,
                end-date: (+ stacks-block-height duration),
                status: "active"
            }
        ))
    )
)