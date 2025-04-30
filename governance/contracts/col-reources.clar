;; Interplanetary Soil Rehabilitation Initiative Smart Contract - v2.0.0 (Enhanced Controls)
;; Facilitates contributions to off-world soil restoration projects and manages colony eligibility
;; with enhanced program controls and soil status tracking

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-COLONY-ALREADY-REGISTERED (err u101))
(define-constant ERR-COLONY-NOT-REGISTERED (err u102))
(define-constant ERR-RESOURCES-UNAVAILABLE (err u103))
(define-constant ERR-CONTRIBUTION-TOO-SMALL (err u104))
(define-constant ERR-PROGRAM-PAUSED (err u105))
(define-constant ERR-CONTRIBUTION-INVALID (err u106))
(define-constant ERR-SOIL-STATUS-INVALID (err u107))

;; Core Program Variables
(define-data-var terraforming-director principal tx-sender)
(define-data-var rehabilitation-vault uint u0)
(define-data-var program-is-active bool true)
(define-data-var contribution-minimum uint u1000000) ;; 1 STX

;; Data Storage
(define-map rehabilitation-colonies 
    principal 
    {
        colony-active: bool,
        resources-allocated: uint,
        last-allocation-block: uint,
        soil-status: (string-ascii 20)
    }
)

(define-map pioneer-registry
    principal
    {
        total-contributions: uint,
        latest-contribution-block: uint
    }
)

;; Read-only Functions
(define-read-only (get-terraforming-director)
    (var-get terraforming-director)
)

(define-read-only (get-rehabilitation-vault)
    (var-get rehabilitation-vault)
)

(define-read-only (get-colony-info (colony-address principal))
    (map-get? rehabilitation-colonies colony-address)
)

(define-read-only (get-pioneer-info (pioneer-address principal))
    (map-get? pioneer-registry pioneer-address)
)

(define-read-only (check-program-status)
    (var-get program-is-active)
)

;; Helper Functions
(define-private (is-director)
    (is-eq tx-sender (var-get terraforming-director))
)

(define-private (record-contribution (pioneer-address principal) (contribution-amount uint))
    (let (
        (pioneer-record (default-to 
            { total-contributions: u0, latest-contribution-block: u0 } 
            (map-get? pioneer-registry pioneer-address)
        ))
    )
    (map-set pioneer-registry
        pioneer-address
        {
            total-contributions: (+ (get total-contributions pioneer-record) contribution-amount),
            latest-contribution-block: block-height
        }
    ))
)

;; Validation Functions
(define-private (is-contribution-valid (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Upper limit for sanity check
    )
)

(define-private (is-soil-status-valid (status-code (string-ascii 20)))
    (or 
        (is-eq status-code "fertile")
        (is-eq status-code "processing")
        (is-eq status-code "barren")
        (is-eq status-code "sustaining")
    )
)

;; Public Functions
(define-public (contribute-to-terraforming)
    (let (
        (contribution-amount (stx-get-balance tx-sender))
    )
    (asserts! (>= contribution-amount (var-get contribution-minimum)) ERR-CONTRIBUTION-TOO-SMALL)
    (asserts! (var-get program-is-active) ERR-PROGRAM-PAUSED)
    
    (try! (stx-transfer? contribution-amount tx-sender (as-contract tx-sender)))
    (var-set rehabilitation-vault (+ (var-get rehabilitation-vault) contribution-amount))
    (record-contribution tx-sender contribution-amount)
    (ok contribution-amount))
)

;; Colony Management
(define-public (register-rehabilitation-colony (colony-address principal))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? rehabilitation-colonies colony-address)) ERR-COLONY-ALREADY-REGISTERED)
        
        (map-set rehabilitation-colonies 
            colony-address
            {
                colony-active: true,
                resources-allocated: u0,
                last-allocation-block: u0,
                soil-status: "barren"
            }
        )
        (ok true)
    )
)

(define-public (allocate-resources (colony-address principal) (resource-amount uint))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (asserts! (var-get program-is-active) ERR-PROGRAM-PAUSED)
        (asserts! (>= (var-get rehabilitation-vault) resource-amount) ERR-RESOURCES-UNAVAILABLE)
        (asserts! 
            (is-some (map-get? rehabilitation-colonies colony-address)) 
            ERR-COLONY-NOT-REGISTERED
        )
        
        (try! (as-contract (stx-transfer? resource-amount tx-sender colony-address)))
        (var-set rehabilitation-vault (- (var-get rehabilitation-vault) resource-amount))
        
        (let (
            (colony-info (unwrap! (map-get? rehabilitation-colonies colony-address) ERR-COLONY-NOT-REGISTERED))
        )
        (map-set rehabilitation-colonies
            colony-address
            {
                colony-active: (get colony-active colony-info),
                resources-allocated: (+ (get resources-allocated colony-info) resource-amount),
                last-allocation-block: block-height,
                soil-status: (get soil-status colony-info)
            }
        )
        (ok resource-amount))
    )
)

;; Administrative Functions
(define-public (set-contribution-minimum (new-minimum uint))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (asserts! (is-contribution-valid new-minimum) ERR-CONTRIBUTION-INVALID)
        (var-set contribution-minimum new-minimum)
        (ok true)
    )
)

(define-public (toggle-program-status)
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (var-set program-is-active (not (var-get program-is-active)))
        (ok true)
    )
)

(define-public (update-soil-status (colony-address principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (asserts! (is-soil-status-valid new-status) ERR-SOIL-STATUS-INVALID)
        (asserts! 
            (is-some (map-get? rehabilitation-colonies colony-address)) 
            ERR-COLONY-NOT-REGISTERED
        )
        
        (let (
            (current-info (unwrap! (map-get? rehabilitation-colonies colony-address) ERR-COLONY-NOT-REGISTERED))
        )
        (map-set rehabilitation-colonies
            colony-address
            {
                colony-active: (get colony-active current-info),
                resources-allocated: (get resources-allocated current-info),
                last-allocation-block: (get last-allocation-block current-info),
                soil-status: new-status
            }
        )
        (ok true))
    )
)

(define-public (change-director (new-director-address principal))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (var-set terraforming-director new-director-address)
        (ok true)
    )
)