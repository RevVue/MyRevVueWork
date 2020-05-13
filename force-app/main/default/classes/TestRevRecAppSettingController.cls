@isTest(SeeAllData=true)
private class TestRevRecAppSettingController {
   
    static testMethod void testControllerActions() {
        Pagereference thePage = Page.RevRecAppSetting;
        Test.setCurrentPage(thePage);
        
        //Verify that AppSetting record is not null
        RevRecAppSettingController theController = new RevRecAppSettingController();
        System.assert(theController.AppSettings != null);

        String currentPageUrl = ApexPages.currentPage().getUrl();
        //Test ConstrollerActions
        System.assertNotEquals(theController.getSelectedStartDate(), null);
        System.assertNotEquals(theController.getUnSelectedStartDate(), null);
        System.assertNotEquals(theController.getSelectedEndDate(), null);
        System.assertNotEquals(theController.getUnSelectedEndDate(), null);
        System.assertNotEquals(theController.getSelectedOpportunityType(), null);
        System.assertNotEquals(theController.getUnSelectedOpportunityType(), null);
        System.assertNotEquals(theController.getSelectedOpportunityStage(), null);
        System.assertNotEquals(theController.getUnSelectedOpportunityStage(), null);
        System.assertNotEquals(theController.getShowDateOfMonth (), null);
        System.assertNotEquals(theController.getShowCertainWeekDay (), null);
        System.assertNotEquals(theController.getMonthDaySelectOptions(), null);
        System.assertNotEquals(theController.getTimeofMonthSelectOptions(), null);
        
        // Verify click cancel will stay in the same page
        System.assertEquals(theController.cancel(), null);
        
        System.assertEquals(theController.StartSelectClick(), null);
        System.assertEquals(theController.StartUnSelectClick(), null);
        System.assertEquals(theController.EndSelectClick(), null);
        System.assertEquals(theController.EndUnSelectClick(), null);
        System.assertEquals(theController.OpportunityTypeSelectClick(), null);
        System.assertEquals(theController.OpportunityTypeUnSelectClick(), null);
        System.assertEquals(theController.OpportunityStageSelectClick(), null);
        System.assertEquals(theController.OpportunityStageUnSelectClick(), null);
        
        theController.AppSettings.Time_of_Month_Selection_Types__c = '1';
        System.assertEquals(theController.TimeOfMonthSelectionTypes(), null);
        System.assertNotEquals(theController.save(), null);
        System.assertEquals('1', theController.AppSettings.Time_of_Month_Selection_Types__c);
        
        //Code modified - Calling controller method for coverage 
        boolean var = true;
        theController.AppSettings.Time_of_Month_Selection_Types_tr__c = '2';
        theController.TimeOfMonthSelectionTypesTr();
        theController.AppSettings.Time_of_Month_Selection_Types_tr__c = '3';
        theController.TimeOfMonthSelectionTypesTr();       
        theController.getShowCertainWeekDayTr();
        theController.setShowDateOfMonthTr(var);
        theController.setShowCertainWeekDayTr(var);
        theController.setShowDateOfMonthTr(var);
        theController.setShowDateOfMonth(var);
        theController.setShowCertainWeekDay(var);
        theController.getShowDateOfMonthTr();
        theController.getChartPreference();
        theController.chartPreferenceToShow();
        theController.getSelectedOpportunityRecordType();
        theController.getUnSelectedOpportunityRecordType();
        theController.OpportunityRecordTypeSelectClick();
        theController.OpportunityRecordTypeUnSelectClick();
            
        //To cover wrapper class var
        OpportunityLineItemWrapper wrap = new OpportunityLineItemWrapper();
        Date d = wrap.CalculatedAt;
    }
}