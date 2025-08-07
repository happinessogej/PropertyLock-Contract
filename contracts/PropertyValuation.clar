;; Property Valuation and Market Analytics Contract
;; Provides automated property valuation and market analysis capabilities

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-invalid-input (err u202))
(define-constant err-unauthorized (err u203))
(define-constant err-already-exists (err u204))

;; Data variables
(define-data-var valuation-counter uint u0)
(define-data-var market-trend-counter uint u0)

;; Property valuations map
(define-map property-valuations
    { property-id: uint }
    {
        current-value: uint,
        last-updated: uint,
        valuation-method: (string-ascii 20),
        confidence-score: uint,
        valuer: principal,
        factors-considered: uint,
        market-conditions: (string-ascii 15),
    }
)

;; Valuation history for tracking value changes over time
(define-map valuation-history
    {
        property-id: uint,
        valuation-id: uint,
    }
    {
        valuation-amount: uint,
        valuation-date: uint,
        method-used: (string-ascii 20),
        market-score: uint,
        valuer: principal,
        notes: (string-ascii 200),
    }
)

;; Comparative market analysis data
(define-map market-comparables
    {
        property-id: uint,
        comparable-id: uint,
    }
    {
        comparable-property-id: uint,
        distance-factor: uint,
        size-factor: uint,
        age-factor: uint,
        condition-factor: uint,
        adjusted-price: uint,
        weight: uint,
    }
)

;; Market trends tracking
(define-map market-trends
    {
        area-code: uint,
        period: uint,
    }
    {
        average-price: uint,
        price-change: uint,
        sales-volume: uint,
        days-on-market: uint,
        trend-direction: (string-ascii 10),
        data-points: uint,
        updated-date: uint,
    }
)

;; Property market factors
(define-map property-factors
    { property-id: uint }
    {
        location-score: uint,
        size-sqft: uint,
        bedrooms: uint,
        bathrooms: uint,
        age-years: uint,
        condition-score: uint,
        amenities-score: uint,
        neighborhood-score: uint,
    }
)

;; Price predictions
(define-map price-predictions
    { property-id: uint }
    {
        predicted-price-3m: uint,
        predicted-price-6m: uint,
        predicted-price-12m: uint,
        prediction-confidence: uint,
        prediction-date: uint,
        model-version: uint,
    }
)

;; Public functions

;; Set property factors for valuation calculation
(define-public (set-property-factors
        (property-id uint)
        (location-score uint)
        (size-sqft uint)
        (bedrooms uint)
        (bathrooms uint)
        (age-years uint)
        (condition-score uint)
        (amenities-score uint)
        (neighborhood-score uint)
    )
    (begin
        (asserts! (> size-sqft u0) err-invalid-input)
        (asserts! (<= location-score u100) err-invalid-input)
        (asserts! (<= condition-score u100) err-invalid-input)
        (asserts! (<= amenities-score u100) err-invalid-input)
        (asserts! (<= neighborhood-score u100) err-invalid-input)
        (ok (map-set property-factors { property-id: property-id } {
            location-score: location-score,
            size-sqft: size-sqft,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            age-years: age-years,
            condition-score: condition-score,
            amenities-score: amenities-score,
            neighborhood-score: neighborhood-score,
        }))
    )
)

;; Calculate automated property valuation
(define-public (calculate-property-valuation
        (property-id uint)
        (base-price-per-sqft uint)
        (market-multiplier uint)
    )
    (let (
            (factors (unwrap! (map-get? property-factors { property-id: property-id }) err-not-found))
            (size (get size-sqft factors))
            (base-value (* size base-price-per-sqft))
            (location-adjustment (/ (* base-value (get location-score factors)) u100))
            (condition-adjustment (/ (* base-value (get condition-score factors)) u100))
            (amenities-adjustment (/ (* base-value (get amenities-score factors)) u50))
            (neighborhood-adjustment (/ (* base-value (get neighborhood-score factors)) u100))
            (age-depreciation (/ (* base-value (get age-years factors)) u200))
            (adjusted-value (+ base-value location-adjustment condition-adjustment))
            (final-value (+ adjusted-value (- amenities-adjustment age-depreciation)))
            (market-adjusted-value (/ (* final-value market-multiplier) u100))
            (confidence-score (/ (+ (get location-score factors) (get condition-score factors) (get neighborhood-score factors)) u3))
            (new-valuation-id (+ (var-get valuation-counter) u1))
        )
        (var-set valuation-counter new-valuation-id)
        (map-set property-valuations { property-id: property-id } {
            current-value: market-adjusted-value,
            last-updated: stacks-block-height,
            valuation-method: "automated",
            confidence-score: confidence-score,
            valuer: tx-sender,
            factors-considered: u8,
            market-conditions: "normal",
        })
        (map-set valuation-history {
            property-id: property-id,
            valuation-id: new-valuation-id,
        } {
            valuation-amount: market-adjusted-value,
            valuation-date: stacks-block-height,
            method-used: "automated",
            market-score: market-multiplier,
            valuer: tx-sender,
            notes: "Automated valuation calculation",
        })
        (ok market-adjusted-value)
    )
)

;; Add comparable property for CMA
(define-public (add-comparable-property
        (property-id uint)
        (comparable-id uint)
        (comparable-property-id uint)
        (distance-factor uint)
        (size-factor uint)
        (age-factor uint)
        (condition-factor uint)
        (adjusted-price uint)
        (weight uint)
    )
    (begin
        (asserts! (<= distance-factor u100) err-invalid-input)
        (asserts! (<= size-factor u150) err-invalid-input)
        (asserts! (<= age-factor u120) err-invalid-input)
        (asserts! (<= condition-factor u120) err-invalid-input)
        (asserts! (<= weight u100) err-invalid-input)
        (ok (map-set market-comparables {
            property-id: property-id,
            comparable-id: comparable-id,
        } {
            comparable-property-id: comparable-property-id,
            distance-factor: distance-factor,
            size-factor: size-factor,
            age-factor: age-factor,
            condition-factor: condition-factor,
            adjusted-price: adjusted-price,
            weight: weight,
        }))
    )
)

;; Update market trends for an area
(define-public (update-market-trends
        (area-code uint)
        (period uint)
        (average-price uint)
        (price-change uint)
        (sales-volume uint)
        (days-on-market uint)
        (trend-direction (string-ascii 10))
        (data-points uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> data-points u0) err-invalid-input)
        (ok (map-set market-trends {
            area-code: area-code,
            period: period,
        } {
            average-price: average-price,
            price-change: price-change,
            sales-volume: sales-volume,
            days-on-market: days-on-market,
            trend-direction: trend-direction,
            data-points: data-points,
            updated-date: stacks-block-height,
        }))
    )
)

;; Generate price predictions
(define-public (generate-price-predictions
        (property-id uint)
        (current-value uint)
        (market-growth-rate uint)
        (volatility-factor uint)
    )
    (let (
            (growth-3m (/ (* current-value (+ u100 market-growth-rate)) u400))
            (growth-6m (/ (* current-value (+ u100 market-growth-rate)) u200))
            (growth-12m (/ (* current-value (+ u100 market-growth-rate)) u100))
            (volatility-adjustment (/ volatility-factor u10))
            (predicted-3m (+ current-value (- growth-3m volatility-adjustment)))
            (predicted-6m (+ current-value (- growth-6m volatility-adjustment)))
            (predicted-12m (+ current-value (- growth-12m volatility-adjustment)))
            (confidence (- u100 volatility-factor))
        )
        (asserts! (> current-value u0) err-invalid-input)
        (asserts! (<= volatility-factor u100) err-invalid-input)
        (ok (map-set price-predictions { property-id: property-id } {
            predicted-price-3m: predicted-3m,
            predicted-price-6m: predicted-6m,
            predicted-price-12m: predicted-12m,
            prediction-confidence: confidence,
            prediction-date: stacks-block-height,
            model-version: u1,
        }))
    )
)

;; Professional valuation override
(define-public (professional-valuation
        (property-id uint)
        (valuation-amount uint)
        (method (string-ascii 20))
        (notes (string-ascii 200))
    )
    (let ((new-valuation-id (+ (var-get valuation-counter) u1)))
        (asserts! (> valuation-amount u0) err-invalid-input)
        (var-set valuation-counter new-valuation-id)
        (map-set property-valuations { property-id: property-id } {
            current-value: valuation-amount,
            last-updated: stacks-block-height,
            valuation-method: method,
            confidence-score: u95,
            valuer: tx-sender,
            factors-considered: u10,
            market-conditions: "professional",
        })
        (ok (map-set valuation-history {
            property-id: property-id,
            valuation-id: new-valuation-id,
        } {
            valuation-amount: valuation-amount,
            valuation-date: stacks-block-height,
            method-used: method,
            market-score: u100,
            valuer: tx-sender,
            notes: notes,
        }))
    )
)

;; Read-only functions

;; Get current property valuation
(define-read-only (get-property-valuation (property-id uint))
    (map-get? property-valuations { property-id: property-id })
)

;; Get property factors
(define-read-only (get-property-factors (property-id uint))
    (map-get? property-factors { property-id: property-id })
)

;; Get valuation history entry
(define-read-only (get-valuation-history
        (property-id uint)
        (valuation-id uint)
    )
    (map-get? valuation-history {
        property-id: property-id,
        valuation-id: valuation-id,
    })
)

;; Get comparable property data
(define-read-only (get-comparable-property
        (property-id uint)
        (comparable-id uint)
    )
    (map-get? market-comparables {
        property-id: property-id,
        comparable-id: comparable-id,
    })
)

;; Get market trends
(define-read-only (get-market-trends
        (area-code uint)
        (period uint)
    )
    (map-get? market-trends {
        area-code: area-code,
        period: period,
    })
)

;; Get price predictions
(define-read-only (get-price-predictions (property-id uint))
    (map-get? price-predictions { property-id: property-id })
)

;; Calculate value appreciation
(define-read-only (calculate-appreciation
        (original-value uint)
        (current-value uint)
        (time-period uint)
    )
    (let (
            (value-change (if (> current-value original-value)
                (- current-value original-value)
                u0
            ))
            (appreciation-rate (if (> original-value u0)
                (/ (* value-change u100) original-value)
                u0
            ))
            (annualized-rate (if (> time-period u0)
                (/ appreciation-rate time-period)
                u0
            ))
        )
        (ok {
            value-change: value-change,
            appreciation-rate: appreciation-rate,
            annualized-rate: annualized-rate,
        })
    )
)

;; Get market health score
(define-read-only (get-market-health-score
        (area-code uint)
        (period uint)
    )
    (match (get-market-trends area-code period)
        trend (let (
                (price-stability (if (< (get price-change trend) u10) u30 u10))
                (volume-score (if (> (get sales-volume trend) u50) u25 u10))
                (time-score (if (< (get days-on-market trend) u30) u25 u10))
                (data-quality (if (> (get data-points trend) u20) u20 u10))
                (total-score (+ price-stability volume-score time-score data-quality))
            )
            (ok total-score)
        )
        err-not-found
    )
)

;; Check if valuation is recent
(define-read-only (is-valuation-recent
        (property-id uint)
        (max-age-blocks uint)
    )
    (match (get-property-valuation property-id)
        valuation (ok (< (- stacks-block-height (get last-updated valuation)) max-age-blocks))
        err-not-found
    )
)

