use starknet::ContractAddress;
#[starknet::interface]
trait escs<TContractState> {
    fn set_offer(ref self: TContractState, nftTokenId: u256, time: u256, apr: u256, amount: u256, paymentToken: ContractAddress, borrower: ContractAddress, liqPrice: u256, ethNftAddressFirstHalf: felt252, ethNftAddressSecondHalf: felt252);
    fn set_start(ref self: TContractState);
    fn read_values(self: @TContractState) -> (u256, u256, u256, u256);
    fn read_addresses(self: @TContractState) -> (ContractAddress, ContractAddress, ContractAddress);
    fn read_nft_contract_address(self: @TContractState) -> (felt252, felt252);
    fn pay(ref self: TContractState);
    fn check_liquidate(ref self: TContractState, priceAtm: u256);
    fn new(ref self: TContractState);
}
#[starknet::interface]
trait IERC20<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;
}



#[starknet::contract]
mod escrow{
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};//internal functions got seperate dispacther
    //use openzeppelin::token::erc20::ERC20;
    use starknet::get_caller_address;
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::contract_address_const;
    

    use super::escs;
    
    #[storage]
    struct Storage {
        state: u8, //0 means not started, 1 means started, 2 means paid, 3 liquidated
        owner: ContractAddress,
        nftTokenId: u256,
        day: u256,
        apr: u256,
        amount: u256,
        paymentToken: ContractAddress, //Could be ala saved as dispatcher
        borrower: ContractAddress,
        lender: ContractAddress,
        liqPrice: u256,
        ethNftAddressFirstHalf: felt252,
        ethNftAddressSecondHalf: felt252,

    }
    #[constructor]
    fn constructor(ref self: ContractState, init_owner: ContractAddress) {
        self.owner.write(init_owner);
    }



    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        fn calculateRepayment(ref self: ContractState) -> u256 {
        let day = self.day.read();
        let apr = self.apr.read();
        let amount = self.amount.read();
        return (apr*day*amount/365+amount);
        }
    }

    

    #[external(v0)]
    impl esc of escs<ContractState> {
        fn set_offer(ref self: ContractState, nftTokenId: u256, time: u256, apr: u256, amount: u256, paymentToken: ContractAddress, borrower: ContractAddress,liqPrice: u256, ethNftAddressFirstHalf: felt252, ethNftAddressSecondHalf: felt252) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
            self.nftTokenId.write(nftTokenId);
            self.day.write(time);
            self.apr.write(apr);
            self.amount.write(amount);
            self.paymentToken.write(paymentToken);
            self.borrower.write(borrower);
            self.liqPrice.write(liqPrice);
            self.state.write(1);
            self.ethNftAddressFirstHalf.write(ethNftAddressFirstHalf);
            self.ethNftAddressSecondHalf.write(ethNftAddressSecondHalf);
            
        }
        fn set_start(ref self: ContractState ) {
            self.lender.write(get_caller_address());
        }
        fn read_values(self: @ContractState) -> (u256, u256, u256, u256) {
            (self.nftTokenId.read(), self.day.read(), self.amount.read(),  self.apr.read() )
        }
        fn read_addresses(self: @ContractState) -> (ContractAddress, ContractAddress, ContractAddress) {
            (self.paymentToken.read(), self.borrower.read(), self.lender.read())
        }
        fn read_nft_contract_address(self: @ContractState) -> (felt252, felt252){
            (self.ethNftAddressFirstHalf.read(), self.ethNftAddressSecondHalf.read())
        }
        fn pay(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.borrower.read(), 'Caller is not the borrower');
            //IERC20Dispatcher{contract_address: self.paymentToken.read()}.transfer_from(self.borrower.read(), self.lender.read(), self.calculateRepayment());
            self.state.write(2);
        }
        fn check_liquidate(ref self: ContractState, priceAtm: u256) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
            assert(self.state.read() == 1,'Not waiting to get paid');
            if(priceAtm < self.liqPrice.read()){
                self.state.write(3);
            }//Not assert so we don't fail the transaction
            
        }
        
        fn new(ref self: ContractState){
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
            self.nftTokenId.write(0);
            self.day.write(0);
            self.apr.write(0);
            self.amount.write(0);
            self.paymentToken.write(contract_address_const::<0>());
            self.borrower.write(contract_address_const::<0>());
            self.lender.write(contract_address_const::<0>());
            self.state.write(0);
            self.liqPrice.write(0);
            self.ethNftAddressFirstHalf.write(0);
            self.ethNftAddressSecondHalf.write(0);
        }
  
    }
}
