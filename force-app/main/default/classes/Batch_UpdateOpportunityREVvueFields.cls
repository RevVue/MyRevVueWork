/**
 *  Description     :   Batch is used to update opportunity data to newly created fields prefixed with REVvue.
 *
 *  Created By      :
 *
 *  Created Date    :   09/12/2018
 *
 *  Version         :   V_1.0
 *
 *  Revision Logs   : 
 *      
 **/
global class Batch_UpdateOpportunityREVvueFields implements Database.Batchable<sObject> {

    //Start method
    global Database.QueryLocator start(Database.BatchableContext BC) {

        String query = 'SELECT';

        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();
    
        for(String s : objectFields.keySet()) {   query += ' ' + s + ',';}
        
        // Strip off the last comma if it exists.
        if (query.subString(query.Length()-1,query.Length()) == ','){    query = query.subString(0,query.Length()-1);}
        
        query += ' FROM Opportunity';
        
        System.debug('@@@@ query ' +query);
        
        //query through the lead
        return Database.getQueryLocator(query);
    }
    
    //Execute method
    global void execute(Database.BatchableContext BC, List<Opportunity> opportunities) {
       
        //List to hold opportunities to be updated
        List<Opportunity> opportunitiesToBeUpdated = new List<Opportunity>();
        
        //Check for size
        if(opportunities.size() > 0) {
            //Loop over querried opportunities
            for(Opportunity opp : opportunities) {
                
                //Set flag to false
                Boolean isChange = false;
        
        		//Check for any change 
                /*if(opp.Created_Date__c != null && opp.REVvue_CreatedDate__c != opp.Created_Date__c) {
                	isChange = true;
                    opp.REVvue_CreatedDate__c = opp.Created_Date__c;
                }
                    
                if(opp.Currencey_Type__c != null && opp.REVvue_CurrencyType__c != opp.Currencey_Type__c) {
                    isChange = true;
                    opp.REVvue_CurrencyType__c = opp.Currencey_Type__c;
                }
                    
                if(opp.CurrentGenerators__c != null && opp.REVvue_CurrentGenerators__c != opp.CurrentGenerators__c) {
                    isChange = true;
                    opp.REVvue_CurrentGenerators__c = opp.CurrentGenerators__c;
                }
                    
                if(opp.DeliveryInstallationStatus__c != null && opp.REVvue_DeliveryInsStatus__c != opp.DeliveryInstallationStatus__c) {
                    isChange = true;
                    opp.REVvue_DeliveryInsStatus__c = opp.DeliveryInstallationStatus__c;
                }
                    
                if(opp.Execute_Mass_Calculation__c != null && opp.REVvue_ExecMassCalc__c != opp.Execute_Mass_Calculation__c) {
                    isChange = true;
                    opp.REVvue_ExecMassCalc__c = opp.Execute_Mass_Calculation__c;
                }
                    
                if(opp.Initial_Opportunity__c != null && opp.REVvue_InitialOpp__c != opp.Initial_Opportunity__c) {
                    isChange = true;
                    opp.REVvue_InitialOpp__c = opp.Initial_Opportunity__c;
                }
                    
                if(opp.MainCompetitors__c != null && opp.REVvue_MainCompetitors__c != opp.MainCompetitors__c) {
                    isChange = true;
                    opp.REVvue_MainCompetitors__c = opp.MainCompetitors__c;
                }
                    
                if(opp.OrderNumber__c != null && opp.REVvue_OrderNumber__c != opp.OrderNumber__c) {
                	isChange = true; 
                    opp.REVvue_OrderNumber__c = opp.OrderNumber__c;
            	}
                    
                if(opp.Parent_Opportunity__c != null && opp.REVvue_ParentOpp__c != opp.Parent_Opportunity__c) {
                    isChange = true;
                    opp.REVvue_ParentOpp__c = opp.Parent_Opportunity__c;
                }
                    
                if(opp.RevRecRule__c != null && opp.REVvue_RevRecRule__c != opp.RevRecRule__c) {
                    isChange = true;
                    opp.REVvue_RevRecRule__c = opp.RevRecRule__c;
                }
                    
                if(opp.Rule_Assignment__c != null && opp.REVvue_RuleAssignment__c != opp.Rule_Assignment__c) {
                    isChange = true;
                    opp.REVvue_RuleAssignment__c = opp.Rule_Assignment__c;
                }
                    
                if(opp.TotalDeferred__c != null && opp.REVvue_TotalDeferred__c != opp.TotalDeferred__c) { 
                    isChange = true;
                    opp.REVvue_TotalDeferred__c = opp.TotalDeferred__c;
                }
                
                if(opp.Total_Deferred_weighted__c != null && opp.REVvue_TotalDeferredwei__c != opp.Total_Deferred_weighted__c) { 
                    isChange = true;
                    opp.REVvue_TotalDeferredwei__c = opp.Total_Deferred_weighted__c;
                }
                    
                if(opp.TotalForecasted__c != null && opp.REVvue_TotalForecasted__c != opp.TotalForecasted__c) {
                    isChange = true;
                    opp.REVvue_TotalForecasted__c = opp.TotalForecasted__c;
                }
                    
                if(opp.Total_Forecasted_weighted__c != null && opp.REVvue_TotalForecastedwei__c != opp.Total_Forecasted_weighted__c) {
                    isChange = true;
                    opp.REVvue_TotalForecastedwei__c = opp.Total_Forecasted_weighted__c;
                }
                    
                if(opp.TotalOpportunity__c != null && opp.REVvue_TotalOpportunity__c != opp.TotalOpportunity__c) {
                    isChange = true;
                    opp.REVvue_TotalOpportunity__c = opp.TotalOpportunity__c;
                }
                    
                if(opp.Total_Opportunity_weighted__c != null && opp.REVvue_Total_Opp_wei__c != opp.Total_Opportunity_weighted__c) {
                    isChange = true;
                    opp.REVvue_Total_Opp_wei__c = opp.Total_Opportunity_weighted__c;
                }
                    
                if(opp.TotalRecognized__c != null && opp.REVvue_TotalRecognized__c != opp.TotalRecognized__c) {
                    isChange = true;
                    opp.REVvue_TotalRecognized__c = opp.TotalRecognized__c;
                }
                    
                if(opp.Total_Recognized_weighted__c != null && opp.REVvue_TotalRecognizedwei__c != opp.Total_Recognized_weighted__c) { 
                    isChange = true;
                    opp.REVvue_TotalRecognizedwei__c = opp.Total_Recognized_weighted__c;
                }
                    
                if(opp.TotalResidual__c != null && opp.REVvue_TotalResidual__c != opp.TotalResidual__c) { 
                    isChange = true;
                    opp.REVvue_TotalResidual__c = opp.TotalResidual__c;
                }
                    
                if(opp.Total_Residual_weighted__c != null && opp.REVvue_TotalResidualwei__c != opp.Total_Residual_weighted__c) { 
                    isChange = true;
                    opp.REVvue_TotalResidualwei__c = opp.Total_Residual_weighted__c;
                }
                    
                if(opp.TrackingNumber__c != null && opp.REVvue_TrackingNumber__c != opp.TrackingNumber__c) {
                    isChange = true;
                    opp.REVvue_TrackingNumber__c = opp.TrackingNumber__c;
            	}*/
            	
            	if(isChange) 
            		opportunitiesToBeUpdated.add(opp);
            }
        }
        
        //Update Opporutnity
        if(opportunitiesToBeUpdated.size() > 0)
        	update opportunitiesToBeUpdated;
    }
    
    //Finish method
    global void finish(Database.BatchableContext BC) {}
}