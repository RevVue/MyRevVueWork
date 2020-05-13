trigger Trigger_YearlyRevenueRollup on AppRopozSLN__Yearly_Revenue_Rollups__c (after insert, after update, after delete) {
    if(Trigger.isAfter) {
        //Checking for action and calling helper method 
        if(Trigger.isUpdate || Trigger.isInsert) 
            YearlyRevenueRollupTriggerHelper.calculateAccYearlyRollupOnAccount(Trigger.new, Trigger.oldMap);
        if(Trigger.isDelete)
            YearlyRevenueRollupTriggerHelper.deleteAccYearlyRollups(Trigger.oldMap);
    }
}