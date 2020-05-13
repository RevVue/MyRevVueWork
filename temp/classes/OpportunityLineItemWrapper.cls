public with sharing class OpportunityLineItemWrapper {		
        
        @AuraEnabled 
        public OpportunityLineItem LineItem {set; get;}
        
        @AuraEnabled  
        public RevRecOpportunityLineItem__c RevRecLineItem {set; get;}
        
        @AuraEnabled 
        public Date CalculatedAt {set; get;}
        
        @AuraEnabled 
        public string RuleNameDisplay {set; get;}  
        
        @AuraEnabled 
        public boolean HasOverriddenRule {set; get; } 
        
        //Code added- 02/20/2015 - Added variable 
        @AuraEnabled 
        public String lineItemSalesPrice {get;set;}
         
        @AuraEnabled  
        public String lineItemTotalPrice {get;set;}
        
        @AuraEnabled 
        public String revRecDeferredPrice {get;set;} 
        
        @AuraEnabled 
        public String revRecRecognizedRev {get;set;}
        
        public String revRecDeferredPriceWeighted {get;set;} 
        public String revRecRecognizedRevWeighted {get;set;}
        
        //Code added - 04/19/2016 - FOR line item level rule
        @AuraEnabled 
        public Boolean isSelectedLineItem {get;set;}
        
        //---------------------------
        //@AuraEnabled 
        //public Contract contract {get;set;}
}