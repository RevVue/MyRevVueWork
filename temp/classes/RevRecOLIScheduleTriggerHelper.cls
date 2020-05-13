/**
*  Description     :   This is the helper class for RevRecOLIScheduleTriggerHelper.
*
*  Created Date    :   04/11/2020
*
*  Created By      :   
*
*  Version         :   V_1.0
*
**/
public without  sharing class RevRecOLIScheduleTriggerHelper {
    
    /**
    *  @description    :   This method is used to find the related Rule criteria and stamp related rule on the Product.    
    *
    *  @args           :   Trigger.New, Trigger.oldMap
    *
    *  @return         :   
    **/
    public static void calculateRollupData (List<RevRecOpportunityLineItemSchedule__c> newRROLISches) {
        
        constants.IS_BY_PASS_SCHEDULES_TRIGGER = false;
        //Variable initialization
        Set<Id> setRROLIIds = new Set<Id>();	//Set of RevRecOpportunityLineItem Id
        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        String opportunityId;
        
        //Check if RevRecOpportunityLineItemSchedule list has value
        if(newRROLISches.size() > 0) {
            
            //Loop over newly inserted schedules
            for(RevRecOpportunityLineItemSchedule__c rrOLISche : newRROLISches)
                setRROLIIds.add(rrOLISche.RevRecOpportunityLineItem__c);
            
            //Loop to fetch RevRecOpportunityLineItem
            for(RevRecOpportunityLineItem__c rrOLI : [SELECT Id, Opportunity__c FROM RevRecOpportunityLineItem__c 
                                                      WHERE Id IN: setRROLIIds]) {
                opportunityId = rrOLI.Opportunity__c;
            }
           
            String queryOpp = '';
            
            if(opportunityId != null) {
                
                //Check if, multicurrency is enable
                if(!isMultiCurrencyEnabled)
                    queryOpp += 'SELECT Id, name, CloseDate , TCV_Actual__c, Probability FROM Opportunity  WHERE Id = \''+ opportunityId +'\' LIMIT 1 FOR UPDATE';
                else
                    queryOpp += 'SELECT Id, name, CurrencyIsoCode, CloseDate , TCV_Actual__c, Probability FROM Opportunity WHERE Id = \''+ opportunityId +'\' LIMIT 1 FOR UPDATE';
            }
             
            //Database.query for opp
            List<Opportunity> listOfallOpp = database.query(queryOpp);
             
            if(!system.isBatch() && listOfallOpp.size() > 0) {
                //Calling batch...
                 Batch_MassRollUpRevenueCalculation massRollupCalBatch = new Batch_MassRollUpRevenueCalculation(listOfallOpp);
                
                 //Parameters of ExecuteBatch(context,BatchSize)
                 database.executebatch(massRollupCalBatch,1);
                
            }
        }
        
    }
}