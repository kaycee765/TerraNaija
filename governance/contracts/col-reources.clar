;; Interplanetary Soil Rehabilitation Initiative Smart Contract - v1.0.0 (Core)
;; Facilitates basic contributions to off-world soil restoration projects

;; Error Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-COLONY-ALREADY-REGISTERED (err u101))
(define-constant ERR-COLONY-NOT-REGISTERED (err u102))
(define-constant ERR-RESOURCES-UNAVAILABLE (err u103))
(define-constant ERR-CONTRIBUTION-TOO-SMALL (err u104))

;; Core Program Variables
(define-data-var terraforming-director principal tx-sender)
(define-data-var rehabilitation-vault uint u0)
(define-data-var contribution-minimum uint u1000000) ;; 1 STX

;; Data Storage
(define-map rehabilitation-colonies 
    principal 
    {
        colony-active: bool,
        resources-allocated: uint,
        last-allocation-block: uint
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

;; Public Functions
(define-public (contribute-to-terraforming)
    (let (
        (contribution-amount (stx-get-balance tx-sender))
    )
    (asserts! (>= contribution-amount (var-get contribution-minimum)) ERR-CONTRIBUTION-TOO-SMALL)
    
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
                last-allocation-block: u0
            }
        )
        (ok true)
    )
)

(define-public (allocate-resources (colony-address principal) (resource-amount uint))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
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
                last-allocation-block: block-height
            }
        )
        (ok resource-amount))
    )
)

;; Administrative Functions
(define-public (set-contribution-minimum (new-minimum uint))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (var-set contribution-minimum new-minimum)
        (ok true)
    )
)

(define-public (change-director (new-director-address principal))
    (begin
        (asserts! (is-director) ERR-NOT-AUTHORIZED)
        (var-set terraforming-director new-director-address)
        (ok true)
    )
)