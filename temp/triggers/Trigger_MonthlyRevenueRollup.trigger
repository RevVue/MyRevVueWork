trigger Trigger_MonthlyRevenueRollup on AppRopozSLN__Monthly_Revenue_Rollups__c (after insert, after update, after delete) {
    if(Trigger.isAfter) {
        //Checking for action and calling helper method 
        if(Trigger.isUpdate || Trigger.isInsert) 
            MonthlyRevenueRollupTriggerHelper.calculateAccMonthlyRollupOnAccount(Trigger.new, Trigger.oldMap);
        if(Trigger.isDelete)
            MonthlyRevenueRollupTriggerHelper.deleteAccMonthlyRollups(Trigger.oldMap);
    }
}