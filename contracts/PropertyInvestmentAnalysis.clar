;; Smart Property Investment Analysis System
;; Provides intelligent investment scoring and risk assessment for property investments

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-found (err u301))
(define-constant err-invalid-input (err u302))
(define-constant err-unauthorized (err u303))
(define-constant err-insufficient-data (err u304))

;; Data variables
(define-data-var analysis-counter uint u0)
(define-data-var investment-recommendation-enabled bool true)
(define-data-var market-risk-threshold uint u70)

;; Investment analysis results
(define-map investment-analyses
  { property-id: uint }
  {
    investment-score: uint,
    risk-score: uint,
    rental-yield: uint,
    market-opportunity: uint,
    liquidity-score: uint,
    overall-recommendation: (string-ascii 20),
    confidence-level: uint,
    analysis-date: uint,
    analyzed-by: principal
  }
)

;; Financial projections for properties
(define-map financial-projections
  { property-id: uint }
  {
    projected-rental-income: uint,
    operating-expenses: uint,
    net-operating-income: uint,
    cap-rate: uint,
    cash-on-cash-return: uint,
    break-even-period: uint,
    total-return-projection: uint,
    projection-period: uint
  }
)

;; Risk assessment factors
(define-map risk-assessments
  { property-id: uint }
  {
    market-volatility: uint,
    vacancy-risk: uint,
    liquidity-risk: uint,
    maintenance-risk: uint,
    location-risk: uint,
    economic-risk: uint,
    composite-risk-score: uint,
    risk-category: (string-ascii 15)
  }
)

;; Market opportunity analysis
(define-map market-opportunities
  { property-id: uint }
  {
    below-market-value: bool,
    growth-potential: uint,
    rental-demand: uint,
    development-proximity: uint,
    infrastructure-score: uint,
    opportunity-score: uint,
    opportunity-type: (string-ascii 25)
  }
)

;; Investment recommendation history
(define-map investment-recommendations
  {
    property-id: uint,
    analysis-id: uint
  }
  {
    recommendation: (string-ascii 20),
    target-price: uint,
    expected-roi: uint,
    hold-period: uint,
    exit-strategy: (string-ascii 30),
    reasoning: (string-ascii 200),
    recommendation-date: uint
  }
)

;; Perform comprehensive investment analysis
(define-public (analyze-investment-potential 
    (property-id uint)
    (purchase-price uint)
    (expected-rental-income uint)
    (operating-expense-ratio uint))
  (let
    (
      (analysis-id (+ (var-get analysis-counter) u1))
      (rental-yield (calculate-rental-yield purchase-price expected-rental-income))
      (operating-expenses (/ (* purchase-price operating-expense-ratio) u100))
      (net-income (- expected-rental-income operating-expenses))
      (cap-rate (if (> purchase-price u0) (/ (* net-income u100) purchase-price) u0))
      (investment-score (calculate-investment-score rental-yield cap-rate))
      (risk-score (calculate-composite-risk-score property-id))
      (market-score (calculate-market-opportunity-score property-id))
      (overall-score (/ (+ investment-score market-score (- u100 risk-score)) u3))
      (recommendation (determine-investment-recommendation overall-score risk-score))
    )
    (asserts! (> purchase-price u0) err-invalid-input)
    (asserts! (> expected-rental-income u0) err-invalid-input)
    (asserts! (<= operating-expense-ratio u100) err-invalid-input)
    
    (var-set analysis-counter analysis-id)
    
    ;; Store investment analysis
    (map-set investment-analyses
      { property-id: property-id }
      {
        investment-score: investment-score,
        risk-score: risk-score,
        rental-yield: rental-yield,
        market-opportunity: market-score,
        liquidity-score: (calculate-liquidity-score property-id),
        overall-recommendation: recommendation,
        confidence-level: (calculate-confidence-level investment-score risk-score),
        analysis-date: stacks-block-height,
        analyzed-by: tx-sender
      }
    )
    
    ;; Store financial projections
    (map-set financial-projections
      { property-id: property-id }
      {
        projected-rental-income: expected-rental-income,
        operating-expenses: operating-expenses,
        net-operating-income: net-income,
        cap-rate: cap-rate,
        cash-on-cash-return: rental-yield,
        break-even-period: (calculate-break-even-period purchase-price net-income),
        total-return-projection: (calculate-total-return purchase-price net-income),
        projection-period: u12
      }
    )
    
    (ok analysis-id)
  )
)

;; Calculate rental yield percentage
(define-private (calculate-rental-yield (purchase-price uint) (annual-rental uint))
  (if (> purchase-price u0)
    (/ (* annual-rental u100) purchase-price)
    u0))

;; Calculate investment score based on yield and cap rate
(define-private (calculate-investment-score (rental-yield uint) (cap-rate uint))
  (let
    (
      (yield-score (if (> rental-yield u8) u40 (if (> rental-yield u5) u25 u10)))
      (cap-score (if (> cap-rate u6) u35 (if (> cap-rate u4) u20 u5)))
      (bonus (if (and (> rental-yield u10) (> cap-rate u8)) u25 u0))
    )
    (+ yield-score cap-score bonus)
  )
)

;; Calculate composite risk score
(define-private (calculate-composite-risk-score (property-id uint))
  (let
    (
      (market-vol u20)
      (vacancy-risk u15)
      (liquidity-risk u25)
      (maintenance-risk u10)
      (location-risk u15)
      (economic-risk u15)
      (composite (+ market-vol vacancy-risk liquidity-risk maintenance-risk location-risk economic-risk))
    )
    ;; Store risk assessment
    (map-set risk-assessments
      { property-id: property-id }
      {
        market-volatility: market-vol,
        vacancy-risk: vacancy-risk,
        liquidity-risk: liquidity-risk,
        maintenance-risk: maintenance-risk,
        location-risk: location-risk,
        economic-risk: economic-risk,
        composite-risk-score: composite,
        risk-category: (if (< composite u30) "low" (if (< composite u60) "medium" "high"))
      }
    )
    composite
  )
)

;; Calculate market opportunity score
(define-private (calculate-market-opportunity-score (property-id uint))
  (let
    (
      (below-market true)
      (growth-potential u75)
      (rental-demand u80)
      (development-score u60)
      (infrastructure u70)
      (opportunity-score (/ (+ growth-potential rental-demand development-score infrastructure) u4))
    )
    ;; Store market opportunity analysis
    (map-set market-opportunities
      { property-id: property-id }
      {
        below-market-value: below-market,
        growth-potential: growth-potential,
        rental-demand: rental-demand,
        development-proximity: development-score,
        infrastructure-score: infrastructure,
        opportunity-score: opportunity-score,
        opportunity-type: (if (> opportunity-score u75) "high-growth" 
          (if (> opportunity-score u50) "stable-income" "value-play"))
      }
    )
    opportunity-score
  )
)

;; Calculate liquidity score
(define-private (calculate-liquidity-score (property-id uint))
  (let
    (
      (market-activity u65)
      (price-stability u70)
      (demand-level u75)
    )
    (/ (+ market-activity price-stability demand-level) u3)
  )
)

;; Determine investment recommendation
(define-private (determine-investment-recommendation (overall-score uint) (risk-score uint))
  (if (and (> overall-score u80) (< risk-score u40)) "strong-buy"
    (if (and (> overall-score u65) (< risk-score u60)) "buy"
      (if (and (> overall-score u50) (< risk-score u70)) "hold"
        (if (> risk-score u80) "sell" "neutral"))))
)

;; Calculate confidence level for analysis
(define-private (calculate-confidence-level (investment-score uint) (risk-score uint))
  (let
    (
      (score-confidence (if (> investment-score u60) u30 u15))
      (risk-confidence (if (< risk-score u50) u25 u10))
      (data-confidence u30)
    )
    (+ score-confidence risk-confidence data-confidence)
  )
)

;; Calculate break-even period in months
(define-private (calculate-break-even-period (purchase-price uint) (monthly-net-income uint))
  (if (> monthly-net-income u0)
    (/ purchase-price monthly-net-income)
    u999)
)

;; Calculate total return projection over 5 years
(define-private (calculate-total-return (purchase-price uint) (annual-net-income uint))
  (let
    (
      (five-year-income (* annual-net-income u5))
      (appreciation (/ (* purchase-price u25) u100))
      (total-return (+ five-year-income appreciation))
    )
    (if (> purchase-price u0) (/ (* total-return u100) purchase-price) u0)
  )
)

;; Generate investment recommendation report
(define-public (generate-investment-recommendation 
    (property-id uint)
    (target-purchase-price uint)
    (investment-timeline uint))
  (let
    (
      (analysis (unwrap! (map-get? investment-analyses { property-id: property-id }) err-not-found))
      (projections (unwrap! (map-get? financial-projections { property-id: property-id }) err-not-found))
      (new-recommendation-id (+ (var-get analysis-counter) u1))
      (expected-roi (/ (* (get total-return-projection projections) investment-timeline) u12))
      (exit-strategy (determine-exit-strategy (get overall-recommendation analysis) investment-timeline))
    )
    (asserts! (var-get investment-recommendation-enabled) err-unauthorized)
    
    (map-set investment-recommendations
      {
        property-id: property-id,
        analysis-id: new-recommendation-id
      }
      {
        recommendation: (get overall-recommendation analysis),
        target-price: target-purchase-price,
        expected-roi: expected-roi,
        hold-period: investment-timeline,
        exit-strategy: exit-strategy,
        reasoning: "Based on comprehensive market and financial analysis",
        recommendation-date: stacks-block-height
      }
    )
    
    (ok new-recommendation-id)
  )
)

;; Determine optimal exit strategy
(define-private (determine-exit-strategy (recommendation (string-ascii 20)) (timeline uint))
  (if (is-eq recommendation "strong-buy")
    (if (> timeline u36) "long-term-hold" "flip-opportunity")
    (if (is-eq recommendation "buy")
      "rental-income-focus"
      (if (is-eq recommendation "hold")
        "monitor-and-hold"
        "exit-when-possible")))
)

;; Update market risk factors
(define-public (update-market-risk-factors
    (property-id uint)
    (market-volatility uint)
    (vacancy-rate uint)
    (economic-indicators uint))
  (let
    (
      (existing-risk (map-get? risk-assessments { property-id: property-id }))
      (updated-composite (+ market-volatility vacancy-rate economic-indicators))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= market-volatility u100) err-invalid-input)
    (asserts! (<= vacancy-rate u100) err-invalid-input)
    
    (match existing-risk
      risk-data
      (map-set risk-assessments
        { property-id: property-id }
        (merge risk-data {
          market-volatility: market-volatility,
          vacancy-risk: vacancy-rate,
          economic-risk: economic-indicators,
          composite-risk-score: updated-composite,
          risk-category: (if (< updated-composite u30) "low" (if (< updated-composite u60) "medium" "high"))
        })
      )
      (map-set risk-assessments
        { property-id: property-id }
        {
          market-volatility: market-volatility,
          vacancy-risk: vacancy-rate,
          liquidity-risk: u25,
          maintenance-risk: u10,
          location-risk: u15,
          economic-risk: economic-indicators,
          composite-risk-score: updated-composite,
          risk-category: (if (< updated-composite u30) "low" (if (< updated-composite u60) "medium" "high"))
        }
      )
    )
    
    (ok updated-composite)
  )
)

;; Read-only functions for investment analysis

(define-read-only (get-investment-analysis (property-id uint))
  (map-get? investment-analyses { property-id: property-id })
)

(define-read-only (get-financial-projections (property-id uint))
  (map-get? financial-projections { property-id: property-id })
)

(define-read-only (get-risk-assessment (property-id uint))
  (map-get? risk-assessments { property-id: property-id })
)

(define-read-only (get-market-opportunity (property-id uint))
  (map-get? market-opportunities { property-id: property-id })
)

(define-read-only (get-investment-recommendation (property-id uint) (analysis-id uint))
  (map-get? investment-recommendations { property-id: property-id, analysis-id: analysis-id })
)

(define-read-only (get-investment-summary (property-id uint))
  (let
    (
      (analysis (map-get? investment-analyses { property-id: property-id }))
      (projections (map-get? financial-projections { property-id: property-id }))
      (risk (map-get? risk-assessments { property-id: property-id }))
      (opportunity (map-get? market-opportunities { property-id: property-id }))
    )
    (if (and (is-some analysis) (is-some projections) (is-some risk) (is-some opportunity))
      (some {
        recommendation: (get overall-recommendation (unwrap-panic analysis)),
        investment-score: (get investment-score (unwrap-panic analysis)),
        risk-level: (get risk-category (unwrap-panic risk)),
        expected-yield: (get rental-yield (unwrap-panic analysis)),
        cap-rate: (get cap-rate (unwrap-panic projections)),
        opportunity-type: (get opportunity-type (unwrap-panic opportunity)),
        confidence: (get confidence-level (unwrap-panic analysis))
      })
      none
    )
  )
)

(define-read-only (compare-investment-opportunities (property-id-1 uint) (property-id-2 uint))
  (let
    (
      (analysis-1 (map-get? investment-analyses { property-id: property-id-1 }))
      (analysis-2 (map-get? investment-analyses { property-id: property-id-2 }))
    )
    (if (and (is-some analysis-1) (is-some analysis-2))
      (let
        (
          (data-1 (unwrap-panic analysis-1))
          (data-2 (unwrap-panic analysis-2))
        )
        (some {
          better-investment: (if (> (get investment-score data-1) (get investment-score data-2)) property-id-1 property-id-2),
          score-difference: (if (> (get investment-score data-1) (get investment-score data-2))
            (- (get investment-score data-1) (get investment-score data-2))
            (- (get investment-score data-2) (get investment-score data-1))),
          risk-comparison: (if (< (get risk-score data-1) (get risk-score data-2)) "property-1-lower-risk" "property-2-lower-risk"),
          yield-comparison: (if (> (get rental-yield data-1) (get rental-yield data-2)) "property-1-higher-yield" "property-2-higher-yield")
        })
      )
      none
    )
  )
)

(define-read-only (get-analysis-settings)
  {
    recommendation-enabled: (var-get investment-recommendation-enabled),
    risk-threshold: (var-get market-risk-threshold),
    total-analyses: (var-get analysis-counter)
  }
)
