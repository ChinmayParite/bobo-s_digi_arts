module ArtMarket::DigitalArt {
    use std::string::String;
    use aptos_framework::account;
    use aptos_framework::event;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Error codes
    const INVALID_PRICE: u64 = 1;
    const NOT_LISTED: u64 = 2;
    const NOT_OWNER: u64 = 3;

    /// Struct representing a digital artwork
    struct ArtPiece has key {
        creator: address,
        title: String,
        price: u64,
        listed: bool,
        created_at: u64
    }

    /// Store events in this struct
    struct MarketEvents has key {
        list_events: event::EventHandle<ListingEvent>,
        purchase_events: event::EventHandle<PurchaseEvent>
    }

    /// Event structs
    struct ListingEvent has drop, store {
        art_creator: address,
        price: u64,
        timestamp: u64
    }

    struct PurchaseEvent has drop, store {
        buyer: address,
        seller: address,
        price: u64,
        timestamp: u64
    }

    /// Initialize event store
    fun init_module(account: &signer) {
        move_to(account, MarketEvents {
            list_events: event::new_event_handle<ListingEvent>(account),
            purchase_events: event::new_event_handle<PurchaseEvent>(account)
        });
    }

    /// List a new digital art piece for sale
    public entry fun list_art(
        creator: &signer,
        title: String,
        price: u64
    ) {
        assert!(price > 0, INVALID_PRICE);
        
        let art = ArtPiece {
            creator: account::get_address(creator),
            title,
            price,
            listed: true,
            created_at: timestamp::now_seconds()
        };
        
        move_to(creator, art);
    }

    /// Purchase a listed art piece
    public entry fun purchase_art(
        buyer: &signer,
        creator_address: address
    ) acquires ArtPiece {
        let art = borrow_global_mut<ArtPiece>(creator_address);
        assert!(art.listed, NOT_LISTED);

        let payment = coin::withdraw<AptosCoin>(buyer, art.price);
        coin::deposit(art.creator, payment);
        
        art.listed = false;
    }
}