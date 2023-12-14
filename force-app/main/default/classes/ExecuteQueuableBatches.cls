/*
    Qeueable apex to self-chain when orders are more than 30 as we have a limitation of processing more than 30 orders at endpoints
*/

public with sharing class ExecuteQueuableBatches implements Queueable,Database.AllowsCallouts {
    private Map<Integer, List<OrderInfo>>  records;
    private Integer batchSize;
    private Integer currentBatch;

    //Queueable Jobs
    public ExecuteQueuableBatches(List<OrderInfo> recordsList, Integer batchSize){
        this.records = divideRecordsInBatches(recordsList, batchSize);
        this.batchSize = batchSize;
        this.currentBatch = 1;
    }

    //Iterative Queueable job
    public ExecuteQueuableBatches(Map<Integer, List<OrderInfo>>  records, Integer batchSize, Integer currentBatch){
        this.records = records;
        this.batchSize = batchSize;
        this.currentBatch = currentBatch; 
    }
    // TO-DO: Proper exception handling can be done and seprating the callout class can be done here
    public void execute(QueueableContext context) {
        if(this.records.containsKey(this.currentBatch)){
            Boolean success = false;
            Integer processedRecords = 0;
            try {
                List<OrderInfo> thisBatchRecords = this.records.get(this.currentBatch);
                processedRecords = thisBatchRecords.size();
                HttpRequest req = new HttpRequest();
                req.setEndpoint('callout:OrderNPS/orders');
                req.setMethod('POST');
                req.setBody(JSON.serialize(thisBatchRecords));
                Http http = new Http();
                HTTPResponse res = http.send(req);
                // TODO: This is for imperative Testing and also can be extended for call out status
                if(Test.isRunningTest())
                    insert new CallOutStatus__c (Response__c=res.getBody());
                this.records.remove(this.currentBatch);
                success = true;
            } catch(Exception e){
                System.debug('Exception in queueable jobs chain ==> '+e.getMessage());
                //Handle your relevant custom exception handling and monitoring                
            }
            //TODO to handle call out failure
            Integer nextBatch = this.currentBatch + 1;
            if(this.records.containsKey(nextBatch) && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()){
                //Chain jobs
                System.enqueueJob(new ExecuteQueuableBatches(this.records, this.batchSize, nextBatch));
            }
        } 
    }

    private Map<Integer, List<OrderInfo>> divideRecordsInBatches(List<OrderInfo> recordsList, Integer batchSize){
        Map<Integer, List<OrderInfo>> batchMap = new Map<Integer, List<OrderInfo>>();
            Integer batchCurrSize = 0;
            Integer batchNumber = 1;
            List<OrderInfo> singleBatch = new List<OrderInfo>();    
            for (Integer i = 0; i < recordsList.size(); i++){
                if(batchCurrSize == batchSize){
                    batchMap.put(batchNumber, singleBatch);
                    singleBatch = new List<OrderInfo>();            
                    batchNumber++;
                    batchCurrSize = 0;
                }
                singleBatch.add(recordsList[i]);
                batchCurrSize++;
            }
            if(!singleBatch.isEmpty()){
                batchMap.put(batchNumber, singleBatch);
            } 
          return batchMap;
        } 
        
}