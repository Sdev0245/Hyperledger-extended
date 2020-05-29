function generateCrypto()
{
    cd $1-artifacts
    ../cryptogen generate --config=./$1-crypto.yaml
   cd .. && cp -r ./org3-artifacts/crypto-config/peerOrganizations/org3.example.com ./crypto-config/peerOrganizations
   cd $1-artifacts
    export FABRIC_CFG_PATH=$PWD && ../configtxgen -printOrg Org3MSP > ../crypto-config/peerOrganizations/org3.example.com/$1.json
    cd ..
    cp ./crypto-config/peerOrganizations/org3.example.com/$1.json ./channel-artifacts
    docker-compose -f docker-compose-org3.yaml up -d
    proceed
}
function proceed(){
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem  && export CHANNEL_NAME=mychannel
    export CHANNEL_NAME=mychannel
    docker exec Org3cli /bin/bash -c "echo $ORDERER_CA && echo $CHANNEL_NAME"
  
    docker exec Org3cli /bin/bash -c "CORE_PEER_LOCALMSPID="Org1MSP" &&
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt &&
     CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp &&
     CORE_PEER_ADDRESS=peer0.org1.example.com:7051 &&export -p && 
    peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA"
    docker exec Org3cli /bin/bash -c "configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json"
    docker exec Org3cli /bin/bash -c "jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/org3.json > modified_config.json"
    docker exec Org3cli /bin/bash -c "configtxlator proto_encode --input config.json --type common.Config --output config.pb"
      docker exec Org3cli /bin/bash -c  "configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb"
   docker exec Org3cli /bin/bash -c "configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org3_update.pb"
   docker exec Org3cli /bin/bash -c "configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json"
   docker exec Org3cli /bin/bash -c "cat org3_update.json" > my_data.json
   docker exec Org3cli /bin/bash -c "echo '"'{"'payload'":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'"$(cat my_data.json)"'}}}'"' | jq . > org3_update_in_envelope.json"
   docker exec Org3cli /bin/bash -c  "configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb"
    docker exec Org3cli /bin/bash -c  "peer channel signconfigtx -f org3_update_in_envelope.pb"
    docker exec Org3cli /bin/bash -c "export CORE_PEER_LOCALMSPID="Org2MSP" &&
 CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt &&
 CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp &&
 CORE_PEER_ADDRESS=peer0.org2.example.com:9051 && 
echo peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050 --tls --cafile $ORDERER_CA"

docker exec Org3cli /bin/bash -c "export CORE_PEER_LOCALMSPID="Org3MSP" &&
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt &&
 export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp && 
 export CORE_PEER_ADDRESS=peer0.org3.example.com:11051 && 
 peer channel fetch 0 mychannel.block -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA && 
 peer channel join -b mychannel.block"
}
export IMAGE_TAG=latest
generateCrypto $1