## Take down the whole network
stopAndGenerate(){
    
    ./eyfn.sh down
   
    Generate $1 $2
}
## generate the artifacts
Generate(){
     ./byfn.sh generate 
    echo "This will generate the artifacts and store in crypto-config file"
    if [ $1 == "up" ]
        then 
        BringUpNetwork
    else
        echo "Run the network with up as CLA"
    fi
}
BringUpNetwork(){
    docker-compose -f docker-compose-e2e-template.yaml -f docker-compose-etcdraft2.yaml up -d
    setUpOrg1
}

setUpOrg1(){


   docker exec cli /bin/bash -c "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp &&
    CORE_PEER_ADDRESS=peer0.org1.example.com:7051 &&
    CORE_PEER_LOCALMSPID="Org1MSP" &&
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt && 
    peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem && 
    peer channel join -b mychannel.block"
  
   docker exec cli /bin/bash -c "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp && 
   CORE_PEER_ADDRESS=peer0.org2.example.com:9051 && 
   CORE_PEER_LOCALMSPID=Org2MSP &&
   CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt && 
   peer channel join -b mychannel.block && 
   peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" 
    setUpOrg2

}

setUpOrg2()
{
    rm log.txt
    docker exec cli /bin/bash -c "export -p && 
    peer lifecycle chaincode package mycc.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode/abstore/javascript/ --lang node --label mycc_1 &&
    peer lifecycle chaincode install mycc.tar.gz"

    docker exec cli /bin/bash -c "peer lifecycle chaincode queryinstalled >> log.txt"
    docker exec cli /bin/bash -c "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp &&
    CORE_PEER_ADDRESS=peer0.org2.example.com:9051 &&
    CORE_PEER_LOCALMSPID="Org2MSP" &&
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt &&
    peer lifecycle chaincode install mycc.tar.gz"
    docker exec cli /bin/bash -c "cat log.txt" >> log.txt
   
    PACKAGE_ID=`sed -n '/Package/{s/^Package ID: //; s/, Label:.*$//; p;}' log.txt`
    echo "package_Id $PACKAGE_ID"
    docker exec cli /bin/bash -c "export CC_PACKAGE_ID=$PACKAGE_ID"
    export CC_PACKAGE_ID=$PACKAGE_ID
    approve    

 }

 approve(){

docker exec cli /bin/bash  -c "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp &&
CORE_PEER_ADDRESS=peer0.org2.example.com:9051 &&
CORE_PEER_LOCALMSPID="Org2MSP" &&
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt &&
peer lifecycle chaincode install mycc.tar.gz &&
peer lifecycle chaincode approveformyorg --channelID $CHANNEL_NAME --name mycc --version 1.0 --init-required --package-id $CC_PACKAGE_ID --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

#FOR ORG1

   docker exec cli /bin/bash -c "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp &&
    CORE_PEER_ADDRESS=peer0.org1.example.com:7051 &&
    CORE_PEER_LOCALMSPID="Org1MSP" &&
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt && peer lifecycle chaincode approveformyorg --channelID $CHANNEL_NAME --name mycc --version 1.0 --init-required --package-id $CC_PACKAGE_ID --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem &&
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name mycc --version 1.0 --init-required --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json && peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID $CHANNEL_NAME --name mycc --version 1.0 --sequence 1 --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
    docker exec cli /bin/bash -c "peer chaincode invoke -o orderer.example.com:7050 --isInit --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C $CHANNEL_NAME -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '"'{"Args":["initLedger"]}'"' --waitForEvent"
}



IMAGE_TAG=latest
CHANNEL_NAME=mychannel
export CHANNEL_NAME
export IMAGE_TAG
stopAndGenerate $1 