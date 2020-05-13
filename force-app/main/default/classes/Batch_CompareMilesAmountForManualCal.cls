/**
 *  Description     :   Batch Class to update Product Rule with AM manual calculation as true.
 *
 *  Created By      :   
 *
 *  Created Date    :   21/02/2018
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :      
 *
**/
global with sharing class Batch_CompareMilesAmountForManualCal implements Database.Batchable<sObject>, Database.Stateful{

    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        //query through the RevRecProductRules 
        return Database.getQueryLocator([SELECT Id, Offset_Period__c, Residual_Amount_Type__c, Period__c, initial_amount_type__c,
                                         Start_Date__c, Residual_Amount__c, Start_Percentage__c, End_Percentage__c,
                                         Initial_Amount__c, Divide_By__c, Period_or_Exact_Days__c,
                                         End_Date__c, RevRecOpportunityLineItem__r.TotalRev__c, Offset_Type__c, RevRecOpportunityLineItem__r.Opportunity__c
                                         FROM RevRecProductRule__c
                                         Where Recognition_Type__c = :Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE]);
    }
   
    //Execute method  
    global void execute(Database.BatchableContext BC, List<RevRecProductRule__c> productRules) {
        
        //Variables
        Double recognizableTotal = 0.0;
        Double residualTotal = 0.0;
        Double residualAmount = 0.0;
        Double initial = 0.0; 
        //Map to hold auto calculated values to be compared with existing miles
        Map<Id, Map<String, RevRecProductRuleMilestone__c>> mapToCompareProRuleIdWithMapOfMiles = new Map<Id, Map<String, RevRecProductRuleMilestone__c>>();
        //List to hold product rule to be update
        List<RevRecProductRule__c> overriddenRulesToUpdated = new List<RevRecProductRule__c>();
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
        Set<Id> setProductRuleIds = new Set<Id>();
        
        //Loop over AM type rules
        for(RevRecProductRule__c prodRule : productRules) {
            
            setProductRuleIds.add(prodRule.Id);

            if(prodRule.Residual_Amount__c != null)
                residualAmount = prodRule.Residual_Amount__c ;
            
            if (prodRule.Residual_Amount_Type__c == 'Percent') 
                residualTotal = (prodRule.RevRecOpportunityLineItem__r.TotalRev__c * residualAmount)/100.0;
            else 
                residualTotal = residualAmount;
            if(prodRule.RevRecOpportunityLineItem__r.TotalRev__c != null)
                recognizableTotal = prodRule.RevRecOpportunityLineItem__r.TotalRev__c;
            if(residualTotal != null)
                recognizableTotal -= residualTotal;
            
            Double initialAmount = (prodRule.initial_amount__c == null) ? 0 : prodRule.initial_amount__c;
            if (prodRule.initial_amount_type__c == 'Percent') 
                initial = recognizableTotal * initialAmount/100.0;
            else 
                initial = initialAmount;
        }
        
        //Map of product Id with miles of existing data
        Map<Id, List<RevRecProductRuleMilestone__c>> mapProdRuleWithExistingMilestones = new Map<Id, List<RevRecProductRuleMilestone__c>>();
        
        //Loop over miles
        for(RevRecProductRuleMilestone__c mile : [SELECT Milestone_Name__c, RevRecProductRule__c, Id, Name, Actual_Amount__c, Projected_Amount__c, Actual_Qty__c,
                                                          Projected_Qty__c, Actual_Percent__c, Projected_Percent__c
                                                          FROM RevRecProductRuleMilestone__c
                                                          WHERE RevRecProductRule__c in :setProductRuleIds]) {
            
            //Populate map
            if(!mapProdRuleWithExistingMilestones.containsKey(mile.RevRecProductRule__c))
                mapProdRuleWithExistingMilestones.put(mile.RevRecProductRule__c, new List<RevRecProductRuleMilestone__c>{mile});
            else
                mapProdRuleWithExistingMilestones.get(mile.RevRecProductRule__c).add(mile);
        }
        
        //Loop over queried data
        for(RevRecProductRule__c prodRule : productRules) {
            
            Date startDate = prodRule.Start_Date__c;
            Date endDate = prodRule.End_Date__c;
            Integer offset = 0;
            Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
            String theOppId = prodRule.RevRecOpportunityLineItem__r.Opportunity__c;
            Opportunity theOppty; 
            
            if(String.isNotBlank(theOppId) && theOppId != null )            
                theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', theOppId);
                
            if (prodRule.Offset_Period__c != null) {
                if(prodRule.offset_type__c == 'Start') {
                    offset = Integer.valueOf(prodRule.Offset_Period__c);
                    IsOffsetStart = true;
                } else if (prodRule.offset_type__c == 'Period'){
                    offset = Integer.valueOf(prodRule.Offset_Period__c);
                    IsOffsetStart = false;
                }
            } 
            
            if (offset > 0) {
                if (IsOffsetStart && (startDate.addMonths(offset) < endDate)) 
                    startDate = startDate.addMonths(offset);        
                else if (!IsOffsetStart) {
                    startDate = startDate.addMonths(offset);
                    endDate = endDate.addMonths(offset);
                }
            }
            
            //Date variables
            Date lastDayOfMonth;
            Integer startDateMonth = startDate.Month();
            Integer startDateYear = startDate.Year();
            Integer endDateMonth = endDate.Month();
            Integer endDateYear = endDate.Year(); 
            Integer totalMonths = startDate.MonthsBetween(endDate);
            
            if (prodRule.Period__c == 'Monthly') {  
                
                List<Decimal> recognizableForEachMonths = new List<Decimal>();
                
                //Total months calculation
                totalMonths = utilHelper.getTotalMonths(startDate, endDate, totalMonths, prodRule);
                
                if(totalMonths == 0)
                    totalMonths =1;

                //Amount calculation
                recognizableForEachMonths = utilHelper.getRecognigibleFORAM(startDate, endDate, prodRule, (recognizableTotal-initial), totalMonths, recognizableForEachMonths, initial);

                //Miles calculation
                mapToCompareProRuleIdWithMapOfMiles = utilHelper.newMilesCalculation(recognizableForEachMonths, totalMonths, prodRule, mapToCompareProRuleIdWithMapOfMiles, startDateMonth, startDateYear, lastDayOfMonth,startDate,recognizableTotal,theOppty.Probability);
            }
        }
        
        //Compare existing and new calculated milestones
        //Loop over Existing Milestones
        for(Id productRuleId : mapProdRuleWithExistingMilestones.keySet()) {
            
            //Flag if manula update
            Boolean IsManulaUpdate = false;
            
            for(RevRecProductRuleMilestone__c miles : mapProdRuleWithExistingMilestones.get(productRuleId)) {
                if(mapToCompareProRuleIdWithMapOfMiles.get(productRuleId).containsKey(miles.Name)) {
                    
                    //Check for actuals
                    if(mapToCompareProRuleIdWithMapOfMiles.get(productRuleId).get(miles.Name).Actual_Amount__c != miles.Actual_Amount__c ||
                       mapToCompareProRuleIdWithMapOfMiles.get(productRuleId).get(miles.Name).Actual_Percent__c != miles.Actual_Percent__c ||
                       mapToCompareProRuleIdWithMapOfMiles.get(productRuleId).get(miles.Name).Actual_Qty__c != miles.Actual_Qty__c) {
                           
                           IsManulaUpdate = true;
                           break;
                    } 
                }
            }
            
            //Check if manual updates
            if(IsManulaUpdate)
                overriddenRulesToUpdated.add(new RevRecProductRule__c(Id = productRuleId, AM_Manual_Cal__c = IsManulaUpdate)); //Adding values in list to update
        }
        
        //Check if list has values to update
        if(overriddenRulesToUpdated.size() > 0) 
            update overriddenRulesToUpdated;    //DML to update product rule
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {
    }
}