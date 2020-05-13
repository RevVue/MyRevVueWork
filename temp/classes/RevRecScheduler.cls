global with sharing class RevRecScheduler implements Schedulable {
    public static String CRON_EXP = '0 0 0 3 9 ? 2022';
    
    global void execute (SchedulableContext SC) {
        Date shedulerDate = Date.Today();
        //step 1: get all opportunityIds which is not need to be calculated again in a day
        
        List<RevRecJob__c> opportunitiesCalculatedToday = [SELECT Id, Name, OpportunityID__c, status_date__c FROM RevRecJob__c LIMIT 50000];
        Set<Id> oppIDs = new Set<id>();
        for (Integer i = 0; i < opportunitiesCalculatedToday.size(); i++ ){
            if (opportunitiesCalculatedToday[i].status_date__c.addDays(1) > shedulerDate) 
                oppIDs.add(opportunitiesCalculatedToday[i].OpportunityID__c);
        }
        
        List<Opportunity> theList = null;
        if (oppIDs.size() > 0) {
            theList = [select Id, Name FROM  Opportunity WHERE id not in :oppIDs order by Name  LIMIT 3000];
        }else {
            theList = [select Id, Name FROM  Opportunity order by Name LIMIT 3000];
        }
        
        RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                    
        if (theList.size() > 0) {
            String oppId = theList[0].id;
            String desp = theList[0].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        }
       
        if (theList.size() > 1) {
            String oppId = theList[1].id;
            String desp = theList[1].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } 
        
        if (theList.size() > 2) {
            String oppId = theList[2].id;
            String desp = theList[2].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } 
      
        if (theList.size() > 3) {
            String oppId = theList[3].id;
            String desp = theList[3].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } 
            
        if (theList.size() > 4) {
            String oppId = theList[4].id;
            String desp = theList[4].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        }              
        
        if (theList.size() > 5) {
            String oppId = theList[5].id;
            String desp = theList[5].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        }
       
        if (theList.size() > 6) {
            String oppId = theList[6].id;
            String desp = theList[6].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } 
        
        if (theList.size() > 7) {
            String oppId = theList[7].id;
            String desp = theList[7].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } 
      
        /*if (theList.size() > 8) {
            String oppId = theList[8].id;
            String desp = theList[8].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } 
            
        if (theList.size() > 9) {
            String oppId = theList[9].id;
            String desp = theList[9].Name;
            utilHelper.ExecuteOpportunityJob(oppId, desp, shedulerDate);
        } */             
        
    }

}