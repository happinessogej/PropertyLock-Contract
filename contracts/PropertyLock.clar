;; PropertyLock Contract
;; Real estate listing subscription platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))


(define-map property-mortgages
    { property-id: uint }
    {
        lender: principal,
        borrower: principal,
        loan-amount: uint,
        interest-rate: uint,
        term-months: uint,
        monthly-payment: uint,
        start-date: uint,
        end-date: uint,
        outstanding-balance: uint,
        payments-made: uint,
        status: (string-ascii 20)
    }
)

(define-map mortgage-payments
    { property-id: uint, payment-id: uint }
    {
        amount: uint,
        payment-date: uint,
        principal-amount: uint,
        interest-amount: uint,
        remaining-balance: uint,
        payment-type: (string-ascii 20)
    }
)

(define-data-var last-payment-id uint u0)

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


;; Define inspection map
(define-map property-inspections
    { property-id: uint, inspection-id: uint }
    {
        inspector: principal,
        date: uint,
        status: (string-ascii 20),
        findings: (string-ascii 500),
        next-inspection: uint
    }
)

;; Add inspection record
(define-public (add-inspection-record 
    (property-id uint) 
    (inspection-id uint)
    (status (string-ascii 20))
    (findings (string-ascii 500))
    (next-inspection uint))
    (begin
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u110))
        (ok (map-set property-inspections
            { property-id: property-id, inspection-id: inspection-id }
            {
                inspector: tx-sender,
                date: stacks-block-height,
                status: status,
                findings: findings,
                next-inspection: next-inspection
            }
        ))
    )
)

;; Define insurance map
(define-map property-insurance
    { property-id: uint }
    {
        provider: (string-ascii 50),
        policy-number: (string-ascii 30),
        coverage-amount: uint,
        start-date: uint,
        end-date: uint,
        status: (string-ascii 20)
    }
)

;; Add insurance record
(define-public (add-insurance-record
    (property-id uint)
    (provider (string-ascii 50))
    (policy-number (string-ascii 30))
    (coverage-amount uint)
    (duration uint))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u111))
        (ok (map-set property-insurance
            { property-id: property-id }
            {
                provider: provider,
                policy-number: policy-number,
                coverage-amount: coverage-amount,
                start-date: stacks-block-height,
                end-date: (+ stacks-block-height duration),
                status: "active"
            }
        ))
    )
)


;; Define tax records map
(define-map property-taxes
    { property-id: uint, year: uint }
    {
        amount: uint,
        paid-amount: uint,
        due-date: uint,
        payment-date: uint,
        status: (string-ascii 20)
    }
)

;; Add tax record
(define-public (add-tax-record
    (property-id uint)
    (year uint)
    (amount uint)
    (due-date uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set property-taxes
            { property-id: property-id, year: year }
            {
                amount: amount,
                paid-amount: u0,
                due-date: due-date,
                payment-date: u0,
                status: "pending"
            }
        ))
    )
)


;; Define amenities map
(define-map property-amenities
    { property-id: uint }
    {
        parking: bool,
        pool: bool,
        gym: bool,
        security: bool,
        elevator: bool,
        last-updated: uint
    }
)

;; Update amenities
(define-public (update-amenities
    (property-id uint)
    (parking bool)
    (pool bool)
    (gym bool)
    (security bool)
    (elevator bool))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u112))
        (ok (map-set property-amenities
            { property-id: property-id }
            {
                parking: parking,
                pool: pool,
                gym: gym,
                security: security,
                elevator: elevator,
                last-updated: stacks-block-height
            }
        ))
    )
)


;; Define occupancy map
(define-map occupancy-history
    { property-id: uint, occupant: principal }
    {
        start-date: uint,
        end-date: uint,
        rent-amount: uint,
        occupancy-type: (string-ascii 20),
        status: (string-ascii 20)
    }
)

;; Add occupancy record
(define-public (add-occupancy-record
    (property-id uint)
    (occupant principal)
    (rent-amount uint)
    (duration uint)
    (occupancy-type (string-ascii 20)))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u113))
        (ok (map-set occupancy-history
            { property-id: property-id, occupant: occupant }
            {
                start-date: stacks-block-height,
                end-date: (+ stacks-block-height duration),
                rent-amount: rent-amount,
                occupancy-type: occupancy-type,
                status: "active"
            }
        ))
    )
)


;; Define utilities map
(define-map property-utilities
    { property-id: uint, month: uint }
    {
        electricity: uint,
        water: uint,
        gas: uint,
        internet: uint,
        payment-status: (string-ascii 20),
        last-reading-date: uint
    }
)

;; Add utility record
(define-public (add-utility-record
    (property-id uint)
    (month uint)
    (electricity uint)
    (water uint)
    (gas uint)
    (internet uint))
    (begin
        (asserts! (is-property-owner property-id tx-sender) (err u114))
        (ok (map-set property-utilities
            { property-id: property-id, month: month }
            {
                electricity: electricity,
                water: water,
                gas: gas,
                internet: internet,
                payment-status: "pending",
                last-reading-date: stacks-block-height
            }
        ))
    )
)


(define-map property-valuations
    { property-id: uint, valuation-id: uint }
    {
        appraiser: principal,
        value: uint,
        date: uint,
        valuation-type: (string-ascii 20),
        supporting-document: (string-ascii 64)
    }
)

(define-data-var last-valuation-id uint u0)

(define-public (add-property-valuation 
    (property-id uint)
    (value uint)
    (valuation-type (string-ascii 20))
    (supporting-document (string-ascii 64)))
    (let
        (
            (new-id (+ (var-get last-valuation-id) u1))
        )
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u200))
        (var-set last-valuation-id new-id)
        (ok (map-set property-valuations
            { property-id: property-id, valuation-id: new-id }
            {
                appraiser: tx-sender,
                value: value,
                date: stacks-block-height,
                valuation-type: valuation-type,
                supporting-document: supporting-document
            }
        ))
    )
)

(define-read-only (get-property-valuation (property-id uint) (valuation-id uint))
    (map-get? property-valuations { property-id: property-id, valuation-id: valuation-id })
)


(define-public (update-property-valuation 
    (property-id uint)
    (valuation-id uint)
    (value uint)
    (valuation-type (string-ascii 20))
    (supporting-document (string-ascii 64)))
    (begin
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u201))
        (ok (map-set property-valuations
            { property-id: property-id, valuation-id: valuation-id }
            {
                appraiser: tx-sender,
                value: value,
                date: stacks-block-height,
                valuation-type: valuation-type,
                supporting-document: supporting-document
            }
        ))
    )
)
(define-public (delete-property-valuation (property-id uint) (valuation-id uint))
    (begin
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u202))
        (ok (map-delete property-valuations { property-id: property-id, valuation-id: valuation-id }))
    )
)

(define-map property-access-slots
    { property-id: uint, slot-id: uint }
    {
        visitor: principal,
        broker: principal,
        start-time: uint,
        end-time: uint,
        status: (string-ascii 20),
        access-code: (string-ascii 10)
    }
)

(define-data-var last-slot-id uint u0)

(define-public (schedule-property-access 
    (property-id uint)
    (visitor principal)
    (start-time uint)
    (end-time uint)
    (access-code (string-ascii 10)))
    (let
        (
            (new-slot-id (+ (var-get last-slot-id) u1))
        )
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u300))
        (asserts! (> end-time start-time) (err u301))
        (var-set last-slot-id new-slot-id)
        (ok (map-set property-access-slots
            { property-id: property-id, slot-id: new-slot-id }
            {
                visitor: visitor,
                broker: tx-sender,
                start-time: start-time,
                end-time: end-time,
                status: "scheduled",
                access-code: access-code
            }
        ))
    )
)

(define-read-only (verify-access-slot 
    (property-id uint) 
    (slot-id uint) 
    (access-code (string-ascii 10)))
    (match (map-get? property-access-slots { property-id: property-id, slot-id: slot-id })
        access-slot (ok (is-eq (get access-code access-slot) access-code))
        err-not-found
    )
)


(define-public (update-access-slot 
    (property-id uint)
    (slot-id uint)
    (start-time uint)
    (end-time uint)
    (access-code (string-ascii 10)))
    (begin
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u302))
        (asserts! (> end-time start-time) (err u303))
        (ok (map-set property-access-slots
            { property-id: property-id, slot-id: slot-id }
            {
                visitor: (unwrap-panic (get visitor (map-get? property-access-slots { property-id: property-id, slot-id: slot-id }))),
                broker: tx-sender,
                start-time: start-time,
                end-time: end-time,
                status: "updated",
                access-code: access-code
            }
        ))
    )
)

(define-public (cancel-access-slot (property-id uint) (slot-id uint))
    (begin
        (asserts! (unwrap-panic (is-verified-broker tx-sender)) (err u304))
        (ok (map-set property-access-slots
            { property-id: property-id, slot-id: slot-id }
            {
                visitor: (unwrap-panic (get visitor (map-get? property-access-slots { property-id: property-id, slot-id: slot-id }))),
                broker: tx-sender,
                start-time: u0,
                end-time: u0,
                status: "cancelled",
                access-code: ""
            }
        ))
    )
)

(define-public (create-mortgage
    (property-id uint)
    (lender principal)
    (borrower principal)
    (loan-amount uint)
    (interest-rate uint)
    (term-months uint)
    (monthly-payment uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> loan-amount u0) (err u400))
        (asserts! (> term-months u0) (err u401))
        (ok (map-set property-mortgages
            { property-id: property-id }
            {
                lender: lender,
                borrower: borrower,
                loan-amount: loan-amount,
                interest-rate: interest-rate,
                term-months: term-months,
                monthly-payment: monthly-payment,
                start-date: stacks-block-height,
                end-date: (+ stacks-block-height (* term-months u144)),
                outstanding-balance: loan-amount,
                payments-made: u0,
                status: "active"
            }
        ))
    )
)

(define-public (record-mortgage-payment
    (property-id uint)
    (amount uint)
    (principal-amount uint)
    (interest-amount uint))
    (let
        (
            (mortgage (unwrap! (map-get? property-mortgages { property-id: property-id }) err-not-found))
            (new-payment-id (+ (var-get last-payment-id) u1))
            (new-balance (- (get outstanding-balance mortgage) principal-amount))
            (new-payments-count (+ (get payments-made mortgage) u1))
        )
        (asserts! (is-eq tx-sender (get borrower mortgage)) (err u402))
        (asserts! (>= amount (get monthly-payment mortgage)) (err u403))
        (var-set last-payment-id new-payment-id)
        (map-set mortgage-payments
            { property-id: property-id, payment-id: new-payment-id }
            {
                amount: amount,
                payment-date: stacks-block-height,
                principal-amount: principal-amount,
                interest-amount: interest-amount,
                remaining-balance: new-balance,
                payment-type: "regular"
            }
        )
        (ok (map-set property-mortgages
            { property-id: property-id }
            (merge mortgage
                {
                    outstanding-balance: new-balance,
                    payments-made: new-payments-count,
                    status: (if (is-eq new-balance u0) "paid-off" "active")
                }
            )
        ))
    )
)

(define-public (initiate-foreclosure (property-id uint))
    (let
        (
            (mortgage (unwrap! (map-get? property-mortgages { property-id: property-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get lender mortgage)) (err u404))
        (asserts! (is-eq (get status mortgage) "active") (err u405))
        (ok (map-set property-mortgages
            { property-id: property-id }
            (merge mortgage { status: "foreclosure" })
        ))
    )
)

(define-public (complete-foreclosure (property-id uint))
    (let
        (
            (mortgage (unwrap! (map-get? property-mortgages { property-id: property-id }) err-not-found))
            (property (unwrap! (get-property property-id) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status mortgage) "foreclosure") (err u406))
        (map-set property-mortgages
            { property-id: property-id }
            (merge mortgage { status: "foreclosed" })
        )
        (ok (map-set properties
            { property-id: property-id }
            (merge property
                {
                    owner: (get lender mortgage),
                    status: "foreclosed"
                }
            )
        ))
    )
)

(define-public (refinance-mortgage
    (property-id uint)
    (new-loan-amount uint)
    (new-interest-rate uint)
    (new-term-months uint)
    (new-monthly-payment uint))
    (let
        (
            (mortgage (unwrap! (map-get? property-mortgages { property-id: property-id }) err-not-found))
        )
        (asserts! (is-eq tx-sender (get borrower mortgage)) (err u407))
        (asserts! (is-eq (get status mortgage) "active") (err u408))
        (ok (map-set property-mortgages
            { property-id: property-id }
            (merge mortgage
                {
                    loan-amount: new-loan-amount,
                    interest-rate: new-interest-rate,
                    term-months: new-term-months,
                    monthly-payment: new-monthly-payment,
                    outstanding-balance: new-loan-amount,
                    start-date: stacks-block-height,
                    end-date: (+ stacks-block-height (* new-term-months u144)),
                    payments-made: u0,
                    status: "refinanced"
                }
            )
        ))
    )
)

(define-read-only (get-mortgage (property-id uint))
    (map-get? property-mortgages { property-id: property-id })
)

(define-read-only (get-mortgage-payment (property-id uint) (payment-id uint))
    (map-get? mortgage-payments { property-id: property-id, payment-id: payment-id })
)

(define-read-only (calculate-remaining-payments (property-id uint))
    (match (get-mortgage property-id)
        mortgage (ok (- (get term-months mortgage) (get payments-made mortgage)))
        err-not-found
    )
)

(define-read-only (is-mortgage-current (property-id uint))
    (match (get-mortgage property-id)
        mortgage 
        (let
            (
                (expected-payments (/ (- stacks-block-height (get start-date mortgage)) u144))
                (actual-payments (get payments-made mortgage))
            )
            (ok (>= actual-payments expected-payments))
        )
        err-not-found
    )
)