/**
 *  Description     :   Batch is used to populate RevRecRule on Line item's from related product.
 *
 *  Created By      :   Bill Feeheley
 *
 *  Created Date    :   04/20/2016
 *
 *  Version         :   V_1.0
 *
 *  Revision Logs   : 
 *      
 **/
global with sharing class Batch_PopulateRuleOnLineItems implements Database.Batchable<sObject>{

    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //query through the lead
        return Database.getQueryLocator([Select Id, Name , AppRopozSLN__RevRecRule__c, Product2Id 
                                         FROM OpportunityLineItem 
                                         where AppRopozSLN__RevRecRule__c = null AND 
                                         Product2Id != null]);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> opportunityLinetems) {
    	
        //Initialization
        Set<Id> product2IdSet = new Set<Id>();
        
        //Check for null
        if(opportunityLinetems.size() > 0) {
            
            //Loop to fetch new values
            for(OpportunityLineItem opportunityLineItem : opportunityLinetems)
            	product2IdSet.add(opportunityLineItem.Product2Id);
            
            //Map to hold product2 values
            Map<Id, Product2> product2Map = new Map<Id, Product2>([Select Id, AppRopozSLN__RevRecRule__c from Product2 
                                 where Id IN : product2IdSet]);
            
            //Loop to fetch new values
            for(OpportunityLineItem opportunityLineItem : opportunityLinetems) {
                
                //Check if map contains Product2Id
                if(product2Map.containsKey(opportunityLineItem.Product2Id)) {
                    
                    //Fetching loop values
                    Product2 product2 = product2Map.get(opportunityLineItem.Product2Id); 
                    
                    //Setting values
                    opportunityLineItem.AppRopozSLN__RevRecRule__c =  product2.AppRopozSLN__RevRecRule__c;
                }
            }
            
            //Updating opportunity line item
            update opportunityLinetems;
        }
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}