# HODLr

Password protected deposits for tokens and ether with time lock feature.

Utils and Interfaces sourced from @OpenZeppelin.

Ensure that your deposit password is sufficienty complex as any wallet that inputs the password is able to make a withdrawal, not just the depositing wallet. You can use the pure function getHash() to get the hash of your chosen password to input with your deposit. If you are withdrawing via an intermediate contract, make sure to include functionality to retrieve your tokens/coins from that contract; this contract send withdraws to the msg.sender, not the tx.origin. The time lock feature can be ignored by using any timestamp prior to the deposit timestamp, ex: 0.
