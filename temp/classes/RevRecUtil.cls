/**
 *  Description     :   This class is used to do all calculation for rules and schedules for all type of rules
 *
 *  Created Date    :    
 *
 *  Version         :   V_1.0
 *
 *  Revision Log    :   V_1.0 - Created 
**/

public with sharing class RevRecUtil { 

    //Variables 
    RevRecAppSetting__c theSetting;
    RevRecRules__c defaultRule;
    public static RevRecAppSetting__c appSetting;
    public String milestoneDateSource;
    Map<String, String> allDates;  
    List<RevRecProductRule__c> overriddenRuleToBeInserted =  new  List<RevRecProductRule__c>();
    Map<String, RevRecOpportunityLineItemSchedule__c> mapScheduleAccordingToMonthAndYear = new Map<String, RevRecOpportunityLineItemSchedule__c>();
    Map<String, List<RevRecScheduleCategory__c>> mapMonthYearScheduleCategories = new Map<String , List<RevRecScheduleCategory__c>>();    
    Map<String , RevRecProductRuleCategory__c> mapOldRuleCategoryIdWithNewCatg = new  Map<String , RevRecProductRuleCategory__c>();
    Map<String,List<Decimal>> mapRecognizableForEachMonthsForBR = new Map<String, List<Decimal>>();
    Map<String, RevRecProductRule__c> mapOldRuleIdWithNewOverrideRule = new Map<String, RevRecProductRule__c>();
    Map<Id, RevRecOpportunityLineItem__c> mapLineItemIdWithRevRecLineItem = new Map<Id, RevRecOpportunityLineItem__c>();
    CalculateBlendedWrapper wrapCalculation = new CalculateBlendedWrapper();
    Map<Id, List<RevRecProductRuleMilestone__c>> mapRuleWithExistingMileStone = new Map<Id, List<RevRecProductRuleMilestone__c>>();
    Map<Id, List<RevRecProductRuleMilestone__c>> mapRROLIIdWithMiles= new Map<Id, List<RevRecProductRuleMilestone__c>>();
    Map<String, List<RevRecProductRuleCategory__c>> mapParentIdWithListOfSplits = new Map<String, List<RevRecProductRuleCategory__c>>();
    Map<Id, RevRecProductRuleCategory__c> mapIdWithAllCatg = new Map<Id, RevRecProductRuleCategory__c>();
    public List<RevRecProductRuleController.ProductRuleCategoryWrapper> listSplitCategoryWrap;
    //If batch is executing to calculate opportunities then Create error log for the failure
    public Boolean IS_EXECUTING_BATCH;
    public static boolean BY_PASS_OPP_LINE_ITEM_TRIGGER = false;
    public static boolean BY_PASS_REVREC_LINE_ITEM_TRIGGER = false;
    Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
    //String to hold user's currency
    String userCurrencyIsoCode = userInfo.getDefaultCurrency();
    Utility utl;    
    RevRecUtilHelper utilHelper;
    Map<String, OpportunityStage> mapStageNameWithAllOppStage = new Map<String, OpportunityStage>();
    
    //Constructer
    public RevRecUtil (){
                
        //Query on Application setting
        List<RevRecAppSetting__c> theSettingList = [SELECT Id, Is_Closed_Date_Validation__c, Name, Opportunity_Stage__c, Opportunity_Type__c,  Selected_Start_Date_Types__c, 
                                                    Selected_End_Date_Types__c, Time_of_Month_Selection_Types__c, 
                                                    Time_of_Month_Selection_Types_tr__c,  Certain_date_of_month__c, Certain_date_of_month_tr__c, 
                                                    Certain_weekday__c, Certain_weekday_tr__c,Certain_weekday_day__c, Certain_weekday_day_tr__c, 
                                                    Certain_days_before_last_weekday__c, Certain_days_before_last_weekday_tr__c, 
                                                    Certain_days_before_last_weekday_day__c, Certain_days_before_last_weekday_day_tr__c, 
                                                    DiagnosticsEnabled__c, Opportunity_Record_Type__c FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
        //Checking for the list size
        if (theSettingList.Size() == 0 )
            theSetting = new RevRecAppSetting__c(Name='AppSetting', Time_of_Month_Selection_Types__c = '1', 
                                                    Time_of_Month_Selection_Types_tr__c = '1');
        else 
            theSetting = theSettingList[0];
        appSetting = theSetting;    //Assigning values 
        defaultRule = null; //Default rule 
   
        //Fetching all rules
        List<RevRecRules__c> allDefaultRules = [SELECT Id,name, Active__c, Default_Rule__c, Description__c, Divide_By__c, 
                                                initial_amount__c, initial_amount_type__c, Offset_Period__c, offset_type__c,Period__c, 
                                                Period_or_Exact_Days__c, Recognition_Type__c, Residual_Amount__c, Residual_Amount_Type__c, 
                                                Revenue_Recognition_End_Date__c,  Revenue_Recognition_Start_Date__c,Milestone_Type__c,
                                                Start_Percentage__c,End_Percentage__c,Is_Split_Categories__c, Enable_Manual_Forecast__c,
                                                Forecast_With_Zero_Value__c,
                                                (Select Id, Name, RevRecRule__c, Milestone_Sequence__c, Milestone_Name__c, Percent__c, Projected_Percent__c
                                                 FROM RevRecRuleMilestones__r ORDER BY Milestone_Sequence__c) 
                                                 FROM RevRecRules__c where  Active__c = true 
                                                 order by AppRopozSLN__Default_Rule__c DESC  limit 1];
                         
        //If many rules then set first as default
        if(allDefaultRules.size() > 0) 
            defaultRule = allDefaultRules[0];
           
        //Fetching all ORG-Date fields related to opportunity and opportunity line items
        allDates = RevRecHelper.getAllOpportunityFieldsWithDateType();
        //Batch execution false 
        IS_EXECUTING_BATCH = false;
        utilHelper = new RevRecUtilHelper();
        
        for(OpportunityStage oppStage : [SELECT Id, Description, MasterLabel FROM  OpportunityStage LIMIT 50000]) 
            mapStageNameWithAllOppStage.put(oppStage.MasterLabel, oppStage);
    }
    
    /**
    *  @description    :    This method is used to calculate for override rule and creating schedule for each rule.
    *
    *  @return         :    String - Msg    
    *
    *  @args           :    Opportunity oppty, List<OpportunityLineItem> lineItems, List<RevRecOpportunityLineItem__c> revReclineItems,
                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules,  
                            OpportunityStage theStage, List<RevRecProductRule__c> overrideRules,
                            Map<Id, List<RevRecProductRuleMilestone__c>> productMilestonesMap,
                            Map<Id, List<RevRecProductRuleCategory__c>> mapLineItemWithProductCategory - Added -  06/17/2015 - As per Blended revenue recognitiion requirement
     **/
    public String EvaluateRevRecSchedule(Opportunity oppty, List<OpportunityLineItem> lineItems, List<RevRecOpportunityLineItem__c> revReclineItems,
                                         List<RevRecOpportunityLineItemSchedule__c> revenuSchedules,  
                                         OpportunityStage theStage, List<RevRecProductRule__c> overrideRules,
                                         Map<Id, List<RevRecProductRuleMilestone__c>> productMilestonesMap,
                                         Map<Id, List<RevRecProductRuleCategory__c>> mapLineItemWithProductCategory){
        //Variable initilization
        String msg = '';
        Decimal probability = oppty.Probability/100;  
        utl = new Utility(oppty);                       
        //List of mileestones
        List<RevRecProductRuleMilestone__c>  productMilestones = new List<RevRecProductRuleMilestone__c>();
        Map<String, RevRecProductRuleMilestone__c> mapMileStonesToBeInserted = new Map<String, RevRecProductRuleMilestone__c>(); 
        //Flag to manage erorr msg
        Boolean isDateNull = false;
        Boolean isRuleNull = false;                                                                 
        String temp = '';
        
        msg = utilHelper.appSettingChecks(theSetting, oppty, theStage);
        if(msg != null && msg != 'null' && msg.length() > 0)
            return msg;

        //Loop through each line item related to opportunity
        for(integer  i = 0; i < lineItems.size(); i++) {
            
            if(lineItems.size() > 0 && lineItems[i].RevRecRule__c == null) {
                OpportunityLinetemTriggerHelper.setRevRecRuleFieldValue(lineItems);
                Constants.IS_BY_PASS_LINE_ITEM_TRIGGER = true;
                if(constants.IS_BY_PASS_LINE_ITEM_TRIGGER) {
                    update lineItems;
                }
            }
            
            if(lineItems[i].RevRecRule__c == null) {
                isRuleNull = true;
                temp += '\r\n -' + revReclineItems[i].ProductName__c;
                continue;
            }
            
            if(overrideRules[i].Name.contains('null'))
                continue;
                
            //Checking for null
            if(productMilestonesMap != null && productMilestonesMap.containsKey(lineItems[i].Id)) {
                
                //Checking for null
                if(productMilestonesMap.get(lineItems[i].Id) != null)
                    productMilestones = productMilestonesMap.get(lineItems[i].Id);
            }
            //If override rule not already exist
            if (overrideRules[i] == null)
                return Constants.NO_RULE + revReclineItems[i].ProductName__c;
                            
            //Start date
            Date startDate;Date endDate = null;

            //Checking for null and calculate start  and end date 
            if(overrideRules[i].Start_Date__c != null)
                startDate = overrideRules[i].Start_Date__c;
            if(overrideRules[i].End_Date__c != null) 
                endDate  = overrideRules[i].End_Date__c; 
            
            //Checking for conditions if start date is null for override rule and show an error msg on page 
            if(startDate == null && (overrideRules[i].Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_MILESTONE && overrideRules[i].Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE))
                isDateNull = true;
            //Checking for conditions if start date is null for override rule and show an error msg on page 
            if(startDate != null && endDate == null && (overrideRules[i].Recognition_Type__c == 'Amortize' || overrideRules[i].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE))
                isDateNull = true;
                
            //Variables
            Double totalRev = LineItems[i].TotalPrice;Double residualTotal = 0;Double recognizedTotal = 0;Double recognizableTotal ;
            Double residualAmount = (overrideRules[i].Residual_Amount__c == null) ? 0 : overrideRules[i].Residual_Amount__c ;
            
            if (overrideRules[i].Residual_Amount_Type__c == 'Percent') 
                residualTotal = (totalRev * residualAmount)/100.0;
            else 
                residualTotal = residualAmount;
            if(totalRev != null)
                recognizableTotal = totalRev;
            if(residualTotal != null)
                recognizableTotal -= residualTotal;

            Date now = Date.Today(); 
            revreclineItems[i].ResidualAmount__c = residualTotal;
            //by default, assign these values
            if (oppty.CloseDate <= now) {
                revreclineItems[i].DeferredRev__c = recognizableTotal;
                revreclineItems[i].DefReWei__c = recognizableTotal * probability;
            }
            //Code modified - (11/16/2016) - Check if multi currency enabled then do this
            if(isMultiCurrencyEnabled)
                revreclineItems[i].put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
            revreclineItems[i].RevRecRule__c = LineItems[i].RevRecRule__c;
            revreclineItems[i].Rule_Assignment__c = LineItems[i].Rule_Assignment__c;
                        
            /***** 1. Rule Type = 'Single Transaction' ******/
            if (overrideRules[i].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                if (startDate == null) {
                    for (Integer j=0; j < 12; j++) {
                        RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                        theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                        theSchedule.OriginalDate__c = oppty.CloseDate.addMonths(j);
                        theSchedule.Date__c = theSchedule.OriginalDate__c;
                        theSchedule.RecognizedRev__c = 0;
                        theSchedule.RecRevWei__c = 0;
                        theSchedule.Recognized_Quantity__c = 0.0;
                        theSchedule.DeferredRev__c = recognizableTotal;
                        theSchedule.DefReWei__c = recognizableTotal * probability;
                        theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                        theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                        theSchedule.Sequence__c = 0;    
                        theSchedule.RecognizedRevTotal__c = 0;
                        theSchedule.Rec_Total_Amt_Wei__c = 0;
                        theSchedule.ResidualAmountTotal__c = residualTotal;
                        theSchedule.LineItemAmountTotal__c = totalRev;
                        theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                        if(isMultiCurrencyEnabled) 
                            theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                        revenuSchedules.add(theSchedule);
                    }
                } else {
                    Integer j = 0;Boolean inCurrentMonth = IsInCurrentMonth(startDate);
                    Date transDateForStarDate = utilHelper.GetTransDate(startDate, inCurrentMonth, theSetting);
                    //Code added - 09/01/2015 - As per RevView new requirement - Milestone
                    if(theSetting.Is_Closed_Date_Validation__c)  {
                        if(oppty.CloseDate > startDate) 
                            return constants.ERROR_MESSAGE_BASED_ON_DATES;
                    }
                     //Checking for the date difference Added on 13 sept
                    if(utilHelper.yearDifference(oppty.CloseDate , startDate) > 10)
                        return constants.START_END_DATE_RANGE_EXCEED;
                    if (oppty.CloseDate < startDate) {            
                        while (oppty.CloseDate.addMonths(j) < startDate) {
                            Date scheduleDate = oppty.CloseDate.addMonths(j) ;
                            j++;
                            if (transDateForStarDate.year() == scheduleDate.year() && transDateForStarDate.month() == scheduleDate.month())
                                continue;  
                            RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                            theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                            theSchedule.OriginalDate__c = scheduleDate;
                            theSchedule.Date__c = theSchedule.OriginalDate__c;
                            theSchedule.RecognizedRev__c = 0;
                            theSchedule.RecRevWei__c = 0;
                            theSchedule.Recognized_Quantity__c = 0;
                            theSchedule.DeferredRev__c = recognizableTotal;
                            theSchedule.DefReWei__c = recognizableTotal * probability;
                            theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                            theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                            theSchedule.Sequence__c = 0;
                            theSchedule.RecognizedRevTotal__c = 0;
                            theSchedule.Rec_Total_Amt_Wei__c = 0;
                            theSchedule.ResidualAmountTotal__c = residualTotal;
                            theSchedule.LineItemAmountTotal__c = totalRev; 
                            theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                            if(isMultiCurrencyEnabled)
                                theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                            revenuSchedules.add(theSchedule);
                        }
                    }
                    RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                    theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                    theSchedule.OriginalDate__c = startDate;
                    theSchedule.Date__c = transDateForStarDate;
                    theSchedule.RecognizedRev__c = recognizableTotal;
                    theSchedule.RecRevWei__c = recognizableTotal * probability;
                    theSchedule.Recognized_Quantity__c = (lineItems[i].TotalPrice == 0) ? 0 : (((theSchedule.RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                    theSchedule.DeferredRev__c = 0;
                    theSchedule.DefReWei__c = 0;
                    theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                    theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                    theSchedule.Sequence__c = 1;
                    theSchedule.RecognizedRevTotal__c = recognizableTotal;
                    theSchedule.Rec_Total_Amt_Wei__c = recognizableTotal * probability;
                    theSchedule.ResidualAmountTotal__c = residualTotal;
                    theSchedule.LineItemAmountTotal__c = totalRev; 
                    theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                   if(isMultiCurrencyEnabled)
                      theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    revenuSchedules.add(theSchedule);
                }
                if (startDate != null && now >= startDate) 
                    revreclineItems[i].RecognizedRev__c = recognizableTotal;
                else    
                    revreclineItems[i].RecognizedRev__c = 0;
                revreclineItems[i].RecRevWei__c = revreclineItems[i].RecognizedRev__c * probability;
                revreclineItems[i].DeferredRev__c = recognizableTotal - revreclineItems[i].RecognizedRev__c;
                revreclineItems[i].DefReWei__c = revreclineItems[i].DeferredRev__c * probability;
                revreclineItems[i].CalculatedAt__c = date.today();
                utilHelper.rrliCalcForSingle(startDate, revreclineItems[i], lineItems[i]); 
            /***** 2. Rule Type = 'Milestone' ******/
            } 
            else if (overrideRules[i].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                 //Code added - 05/13/2015 - As per Milestone Date Automation Functionality
                List<RevRecProductRuleMilestone__c> listProductMileStonesForDates = new  List<RevRecProductRuleMilestone__c>();
                for(RevRecProductRuleMilestone__c miles : productMilestones) {  
                    if(string.isNotBlank(miles.Milestone_Date_Source__c) && miles.Milestone_Date__c != null) 
                        listProductMileStonesForDates.add(miles);   //Add Milestones into list
                } 
                startDate = Date.Today();
                Date endDatemile = startDate.addDays(1);Integer sequence  = 0;
                if (listProductMileStonesForDates != null && listProductMileStonesForDates.size() > 0) {
                    startDate = listProductMileStonesForDates[0].Milestone_Date__c;
                    endDatemile = listProductMileStonesForDates[listProductMileStonesForDates.size() -1 ].Milestone_Date__c;
                } else {
                    startDate = null;
                    endDatemile = null; 
                }

                //Code added - As per RevView new requirement - Milestone
                if(theSetting.Is_Closed_Date_Validation__c)  {
                    if(startDate != null && oppty.CloseDate > startDate)        
                        return constants.ERROR_MESSAGE_BASED_ON_DATES;
                    else if(endDatemile !=  null && oppty.CloseDate > endDate)
                        return constants.ERROR_MESSAGE_BASED_ON_DATES;
                }
                 //Checking for the date difference Added on 13 sept
                 if(oppty.CloseDate != null && endDatemile != null) {
                    if(utilHelper.yearDifference(oppty.CloseDate , endDatemile) > 10)
                        return constants.START_END_DATE_RANGE_EXCEED;
                 }
                if(startDate == null) {
                    for(Integer j=0; j < 12; j++) {
                        RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                        theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                        theSchedule.OriginalDate__c = oppty.CloseDate.addMonths(j);
                        theSchedule.Date__c = theSchedule.OriginalDate__c;
                        theSchedule.RecognizedRev__c = 0;
                        theSchedule.RecRevWei__c = 0;
                        theSchedule.Recognized_Quantity__c = 0;
                        theSchedule.DeferredRev__c = recognizableTotal;
                        theSchedule.DefReWei__c = recognizableTotal * probability;
                        theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                        theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                        theSchedule.Sequence__c = 0;
                        theSchedule.RecognizedRevTotal__c = 0;
                        theSchedule.Rec_Total_Amt_Wei__c = 0;
                        theSchedule.ResidualAmountTotal__c = residualTotal;
                        theSchedule.LineItemAmountTotal__c = totalRev; 
                        theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                        if(isMultiCurrencyEnabled)
                            theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode')); 
                        revenuSchedules.add(theSchedule);
                    }
                } else {                
                    if (oppty.CloseDate < startDate) {
                        while (oppty.CloseDate.addMonths(sequence) < startDate) {
                            Date scheduleDate = oppty.CloseDate.addMonths(sequence) ;
                            sequence++; 
                            if (startDate.year() == scheduleDate.year() && startDate.month() == scheduleDate.month())
                                continue; 
                            RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                            theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                            theSchedule.OriginalDate__c = scheduleDate;
                            theSchedule.Date__c = theSchedule.OriginalDate__c;
                            theSchedule.RecognizedRev__c = 0;
                            theSchedule.RecRevWei__c = 0;
                            theSchedule.Recognized_Quantity__c = 0;
                            theSchedule.DeferredRev__c = recognizableTotal;
                            theSchedule.DefReWei__c = recognizableTotal * probability;
                            theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                            theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                            theSchedule.Sequence__c = 0 ;
                            theSchedule.RecognizedRevTotal__c = 0;
                            theSchedule.Rec_Total_Amt_Wei__c = 0;
                            theSchedule.ResidualAmountTotal__c = residualTotal;
                            theSchedule.LineItemAmountTotal__c = totalRev; 
                            theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                            if(isMultiCurrencyEnabled)
                                theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                            revenuSchedules.add(theSchedule);
                        }
                    }
                }
                string ret =  RecognizeForMilestones(sequence, recognizableTotal, overrideRules[i].Milestone_Type__c, lineItems[i], revrecLineItems[i], productMilestones, revenuSchedules, oppty);

                //Code is added on 7 Dec 2016
                if(overrideRules[i].Id != null && productMilestones != null && overrideRules[i].Is_Default_Overriden__c) {
                    for(RevRecProductRuleMilestone__c miles : productMilestones)    
                        miles.RevRecProductRule__c = overrideRules[i].Id;
                    upsert productMilestones;
                }
                if (ret.length() != 0) 
                    msg += ret + ' for ' + revReclineItems[i].ProductName__c;
                //Calling method to calc remaining amount, remaining percent, remaining qty
                utilHelper.rrliRemainingCalc(lineItems[i],revreclineItems[i], productMilestones, overrideRules[i].Milestone_Type__c, recognizableTotal);
                /***** 3. Rule Type = 'Amortize' ******/
                //Code modified - 04/27/2016 - FEATURE # 13: Modify the Radio Buttons and Calculations for the following options:
                } 
            else if (overrideRules[i].Recognition_Type__c == 'Amortize' || overrideRules[i].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {    //amortized
                    Double initial = 0;
                    Double initialAmount = (overrideRules[i].initial_amount__c == null) ? 0 : overrideRules[i].initial_amount__c;
                    if (overrideRules[i].initial_amount_type__c == 'Percent') 
                        initial = recognizableTotal * initialAmount/100.0;
                    else 
                        initial = initialAmount;
                   //Checking for Opportunity close date is greater than Dates
                    if(theSetting.Is_Closed_Date_Validation__c)  {
                        if(oppty.CloseDate > startDate ) 
                            return constants.ERROR_MESSAGE_BASED_ON_DATES;
                        else if(oppty.CloseDate > endDate)
                            return constants.ERROR_MESSAGE_BASED_ON_DATES;
                    }
                    //Checking for the date difference Added on 13 sept
                    if(startDate != null && endDate != null) {
                        if((overrideRules[i].Period__c == 'daily' && utilHelper.monthDifference(startDate , endDate) > 24) || utilHelper.yearDifference(startDate , endDate) > 10)
                            return constants.START_END_DATE_RANGE_EXCEED;
                        if(endDate < startDate)
                            return Constants.START_END_DATE_ERROR_MESSAGE;
                    } 
                    if(startDate == null || endDate == null)
                        return constants.START_END_DATE_ERROR_MESSAGE;
                    
                    String msz = RevRecUtilHelper.getStartEndPercentageCount(overrideRules[i]);
                    
                    if(String.isNotBlank(msz))
                        return msz;
                    
                    if(overrideRules[i].Recognition_Type__c == 'Amortize') {
                        if(startDate != null) {
                            //if is not monthly, it is wrong anyway
                            Integer sequence  = 0;
                            if(overrideRules[i].Period__c != 'Monthly') {
                                if(oppty.CloseDate < startDate) {
                                    while(oppty.CloseDate.addMonths(sequence) < startDate) {
                                        RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                                        theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                                        theSchedule.OriginalDate__c = oppty.CloseDate.addMonths(sequence);
                                        theSchedule.Date__c = theSchedule.OriginalDate__c;
                                        theSchedule.RecognizedRev__c = 0;
                                        theSchedule.RecRevWei__c = 0;
                                        theSchedule.Recognized_Quantity__c = 0;
                                        theSchedule.DeferredRev__c = recognizableTotal;
                                        theSchedule.DefReWei__c = recognizableTotal * probability;
                                        theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                                        theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                                        theSchedule.Sequence__c = 0 ;
                                        theSchedule.RecognizedRevTotal__c = 0;
                                        theSchedule.Rec_Total_Amt_Wei__c = 0;
                                        theSchedule.ResidualAmountTotal__c = residualTotal;
                                        theSchedule.LineItemAmountTotal__c = totalRev;
                                        theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                                        if(isMultiCurrencyEnabled)
                                            theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                                        revenuSchedules.add(theSchedule);
                                        sequence++;
                                    }
                                }
                            }
                            if(overrideRules[i].Period__c == 'Monthly') {
                                if(overrideRules[i].Total_Period__c != null && Integer.valueOf(overrideRules[i].Total_Period__c) > 0)
                                    endDate = startDate.addMonths(Integer.valueOf(overrideRules[i].Total_Period__c)).addDays(-1);
                                Integer offset = 0;
                                Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                                if(overrideRules[i].Offset_Period__c != null) {
                                    if(overrideRules[i].offset_type__c == 'Start') {
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = true;
                                    } else if (overrideRules[i].offset_type__c == 'Period'){
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = false;
                                    }
                                }
                                if(offset > 0){
                                    if(IsOffsetStart && (startDate.addMonths(offset) < endDate))
                                        startDate = startDate.addMonths(offset);        
                                    else if(!IsOffsetStart){
                                        startDate = startDate.addMonths(offset);
                                        endDate = endDate.addMonths(offset);
                                    }
                                }
                                sequence = 0;Boolean inCurrentMonth = IsInCurrentMonth(startDate);
                                Date transDateForStarDate = utilHelper.GetTransDate(startDate, inCurrentMonth,theSetting);
                                if(oppty.CloseDate < startDate){
                                    while(oppty.CloseDate.addMonths(sequence) < startDate) {
                                        Date scheduleDate = oppty.CloseDate.addMonths(sequence) ;
                                        sequence++;
                                        if (transDateForStarDate.year() == scheduleDate.year() && transDateForStarDate.month() == scheduleDate.month())
                                            continue;
                                        RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                                        theSchedule.OpportunityLineItemId__c = lineItems[i].Id;
                                        theSchedule.OriginalDate__c = scheduleDate;
                                        theSchedule.Date__c = theSchedule.OriginalDate__c;
                                        theSchedule.RecognizedRev__c = 0;
                                        theSchedule.RecRevWei__c = 0;
                                        theSchedule.Recognized_Quantity__c = 0;
                                        theSchedule.DeferredRev__c = recognizableTotal;
                                        theSchedule.DefReWei__c = recognizableTotal * probability;
                                        theSchedule.RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c;
                                        theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                                        theSchedule.Sequence__c = 0 ;
                                        theSchedule.RecognizedRevTotal__c = 0;
                                        theSchedule.Rec_Total_Amt_Wei__c = 0;
                                        theSchedule.ResidualAmountTotal__c = residualTotal;
                                        theSchedule.LineItemAmountTotal__c = totalRev; 
                                        theSchedule.LI_Amt_Total_Wei__c = totalRev * probability;
                                        if(isMultiCurrencyEnabled)
                                            theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                                        revenuSchedules.add(theSchedule);
                                    }
                                } 
                                msg += utilHelper.MonthlyAmortized(overrideRules[i], sequence, recognizableTotal, initial, overrideRules[i].Period_or_Exact_Days__c, startDate, endDate, overrideRules[i].Divide_By__c, oppty, lineItems[i], revrecLineItems[i], revenuSchedules, theSetting);
                            } //period monthly
                            else if(overrideRules[i].Period__c == 'Weekly'){
                                if(overrideRules[i].Total_Period__c != null && Integer.valueOf(overrideRules[i].Total_Period__c) > 0)
                                    endDate = startDate.addDays(Integer.valueOf(overrideRules[i].Total_Period__c) * 7 -1);
                                Integer offset = 0;
                                Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                                if(overrideRules[i].Offset_Period__c != null) {
                                    if(overrideRules[i].offset_type__c == 'Start') {
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = true;
                                    } else if(overrideRules[i].offset_type__c == 'Period'){
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = false;
                                    }
                                }
                                if(offset > 0) {
                                    if(IsOffsetStart && (startDate.addDays(offset * 7) < endDate))
                                        startDate = startDate.addDays(offset * 7);      
                                    else if(!IsOffsetStart) {
                                        startDate = startDate.addDays(offset * 7);
                                        endDate = endDate.addDays(offset * 7);
                                    }
                                }
                                String ret = utilHelper.WeeklyAmortized(overrideRules[i], sequence, recognizableTotal, initial, startDate, endDate, oppty, lineItems[i], revrecLineItems[i], revenuSchedules,theSetting); 
                                if (ret.length() != 0) 
                                    msg += ret + ' for ' + revReclineItems[i].ProductName__c;
                            } //period weekly
                            else if (overrideRules[i].Period__c == 'Yearly'){
                                if (overrideRules[i].Total_Period__c != null && Integer.valueOf(overrideRules[i].Total_Period__c) > 0)
                                    endDate = startDate.addYears(Integer.valueOf(overrideRules[i].Total_Period__c)).addDays(-1);
                                Integer offset = 0;
                                Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                                if (overrideRules[i].Offset_Period__c != null) {
                                    if(overrideRules[i].offset_type__c == 'Start') {
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = true;
                                    } else if (overrideRules[i].offset_type__c == 'Period'){
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = false;
                                    }
                                }
                                if(offset > 0) {
                                    if(IsOffsetStart && (startDate.addYears(offset) < endDate))
                                        startDate = startDate.addYears(offset);     
                                    else if (!IsOffsetStart) {
                                        startDate = startDate.addYears(offset);
                                        endDate = endDate.addYears(offset);
                                    }
                                }
                                String ret = YearlyAmortized(overrideRules[i], sequence, recognizableTotal, initial, startDate, endDate,  oppty, lineItems[i], revrecLineItems[i], revenuSchedules); 
                                if(ret.length() != 0)
                                    msg += ret + ' for ' + revReclineItems[i].ProductName__c;
                            } //period yearly
                            else if(overrideRules[i].Period__c == 'Quarterly'){
                                if (overrideRules[i].Total_Period__c != null && Integer.valueOf(overrideRules[i].Total_Period__c) > 0)
                                    endDate = startDate.addMonths(Integer.valueOf(overrideRules[i].Total_Period__c)*3).addDays(-1);
                                Integer offset = 0;
                                Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                                if(overrideRules[i].Offset_Period__c != null) {
                                    if(overrideRules[i].offset_type__c == 'Start') {
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = true;
                                    } else if(overrideRules[i].offset_type__c == 'Period'){
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = false;
                                    }
                                }
                                if(offset > 0) {
                                    if(IsOffsetStart && (startDate.addMonths(offset*3) < endDate))
                                        startDate = startDate.addMonths(offset*3);      
                                    else if (!IsOffsetStart) {
                                        startDate = startDate.addMonths(offset*3);
                                        endDate = endDate.addMonths(offset*3);
                                    }
                                }
                                String ret = QuartlyAmortized(overrideRules[i], sequence, recognizableTotal, initial, overrideRules[i].Period_or_Exact_Days__c, startDate, endDate, oppty, lineItems[i], revrecLineItems[i], revenuSchedules); 
                                if(ret.length() != 0)
                                    msg += ret + ' for ' + revReclineItems[i].ProductName__c;
                            } //period quarterly
                            else if(overrideRules[i].Period__c == 'daily'){
                                if(overrideRules[i].Total_Period__c != null && Integer.valueOf(overrideRules[i].Total_Period__c) > 0)
                                    endDate = startDate.addDays(Integer.valueOf(overrideRules[i].Total_Period__c)).addDays(-1);
                                Integer offset = 0;Boolean IsOffsetStart = true;
                                if(overrideRules[i].Offset_Period__c != null) {
                                    if(overrideRules[i].offset_type__c == 'Start') {
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = true;
                                    } else if(overrideRules[i].offset_type__c == 'Period'){
                                        offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                        IsOffsetStart = false;
                                    }
                                }
                                if(offset > 0) {
                                    if(IsOffsetStart && (startDate.addDays(offset) < endDate))
                                        startDate = startDate.addDays(offset);      
                                    else if(!IsOffsetStart) {
                                        startDate = startDate.addDays(offset);
                                        endDate = endDate.addDays(offset);
                                    }
                                }
                                String ret = utilHelper.DailyAmortized(overrideRules[i], sequence, recognizableTotal, initial, startDate, endDate, oppty, lineItems[i], revrecLineItems[i], revenuSchedules); 
                                if(ret.length() != 0)
                                    msg += ret + ' for ' + revReclineItems[i].ProductName__c;
                            } //period daily 
                        }
                        utilHelper.rrliCalcForAmortize(startDate, endDate, revReclineItems[i], lineItems[i]);   //end Amortize
                    } else if(overrideRules[i].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                        List<RevRecProductRuleMilestone__c>listMileStone = new List<RevRecProductRuleMilestone__c>();
                        if(startDate != null && endDate != null) {
                            Set<String> setMilestoneNames = new Set<String>();
                            //Code added - 8/11/2016 - As per A to Am changes 
                            if(mapRuleWithExistingMileStone.containsKey(overrideRules[i].Id)) {
                                for(RevRecProductRuleMilestone__c mileStone : mapRuleWithExistingMileStone.get(overrideRules[i].Id)) {
                                    //Popuolatre set of milestone name 
                                    setMilestoneNames.add(mileStone.Name);
                                    listMileStone.add(mileStone);
                                }  
                            }
                            Integer offset = 0;
                            Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                            if(overrideRules[i].Offset_Period__c != null) {
                                if(overrideRules[i].offset_type__c == 'Start') {
                                    offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                    IsOffsetStart = true;
                                } else if (overrideRules[i].offset_type__c == 'Period'){
                                    offset = Integer.valueOf(overrideRules[i].Offset_Period__c);
                                    IsOffsetStart = false;
                                }
                            }
                            if(offset > 0) {
                                if(IsOffsetStart && (startDate.addMonths(offset) < endDate)) 
                                    startDate = startDate.addMonths(offset);        
                                else if(!IsOffsetStart) {
                                    startDate = startDate.addMonths(offset);
                                    endDate = endDate.addMonths(offset);
                                }
                            }
                            Date currentDate = Date.Today();
                            Integer noOfDaysInCurrentMonth = Date.daysInMonth(currentDate.year(), currentDate.month());
                            Date amortCurrentDate = Date.newInstance(currentDate.Year(), currentDate.Month(), currentDate.day());
                            Integer totalMonths = startDate.MonthsBetween(endDate);
                            Date tempDate = startDate.addMonths(totalMonths);
                            Date lastDayOfMonth;Integer numberOfDays;Integer sequence  = 0;
                            Decimal amountPerMonth = 0.00;Decimal quantityPerMonth = 0.00 ;
                            //Variables to hold the month values of start date and end date
                            Integer startDateMonth = startDate.Month();Integer startDateYear = startDate.Year();Integer endDateMonth = endDate.Month();Integer endDateYear = endDate.Year(); 
                            //Month Difference between 
                            Boolean inCurrentMonth = IsInCurrentMonthForBlended(startDate);
                            Date transDate = getTransDateForBlended(startDate , inCurrentMonth);
                            Integer transDay  = transDate.day(); numberOfDays = transDay;
                            Date amortStartDate = Date.newInstance(startDateYear, startDateMonth, numberOfDays);
                            Date newStartDate;Date newStartDateTemp; 
                            if (overrideRules[i].Period__c == 'Monthly') {  
                                List<Decimal> recognizableForEachMonths = new List<Decimal>();
                                totalMonths = utilHelper.getTotalMonths(startDate, endDate, totalMonths, overrideRules[i]);
                                if( totalMonths == 0)
                                    totalMonths =1;
                                recognizableForEachMonths = utilHelper.getRecognigibleFORAM(startDate, endDate, overrideRules[i], (recognizableTotal-initial), totalMonths , recognizableForEachMonths , initial);
                                Set<Id> setMilesIds = new Set<Id>();
                                Integer milesCount = 0;
                                if(listMileStone.size() > 0)
                                    milesCount = listMileStone.size(); 
                                
                                utilHelper.milesCalculation(recognizableForEachMonths, totalMonths, overrideRules[i], setMilestoneNames,mapMileStonesToBeInserted, startDateMonth, startDateYear, lastDayOfMonth,startDate, setMilesIds, milesCount, listMileStone, lineItems[i], probability);
                                
                                //List to hol milestone records to be delete
                                List<RevRecProductRuleMilestone__c> milesToBeDeleted = new List<RevRecProductRuleMilestone__c>();
                                //Check if miles to be delete
                                if(milesCount > 0 && setMilesIds.size() > 0){
                                    //Loop over existing miles
                                    for(RevRecProductRuleMilestone__c mile : listMileStone) {
                                        //Check if existing miles not used for new miles
                                        if(!setMilesIds.contains(mile.Id))
                                            milesToBeDeleted.add(mile); 
                                    }
                                    //Check if miles to be delete
                                    if(RevRecProductRuleMilestone__c.sObjectType.getDescribe().isDeletable()){
                                        if(milesToBeDeleted.size() > 0) 
                                            delete milesToBeDeleted;
                                    }
                                }
                            }
                        //Check for map size if any new milestonne exist 
                        if(mapMileStonesToBeInserted.size() > 0) {
                            Decimal amountPerMonthActual;
                            //Total Recognized Amount
                            Decimal totalRecognozedAmount = revReclineItems[i].RecognizedRev__c != null ? revReclineItems[i].RecognizedRev__c : 0.00;
                            Integer totalAmortMonths = amortStartDate.MonthsBetween(amortCurrentDate); 
                            Date tempDate1 = amortStartDate.addMonths(totalAmortMonths);
                            //Checking for total months
                            if(tempDate1.daysBetween(amortCurrentDate) > 0) 
                                totalAmortMonths = totalAmortMonths+1;
                            if(totalAmortMonths == 0)
                                totalAmortMonths = totalAmortMonths+1;
                            //Amount per month actual
                            amountPerMonthActual = totalRecognozedAmount / totalAmortMonths;
                            //Re-initilize
                            revReclineItems[i].Allocated__c = 0.00;
                            listMileStone = new List<RevRecProductRuleMilestone__c>();
                            //loop through milestone
                            for(RevRecProductRuleMilestone__c mapMile : mapMileStonesToBeInserted.values()){
                                if(mapMile.RevRecProductRule__c == overrideRules[i].Id) {
                                    //Checking for date is less than equal to  
                                    if(mapMile.Milestone_Date__c <= amortCurrentDate && mapMile.Actual_Amount__c == null ) {
                                        mapMile.Actual_Amount__c = amountPerMonthActual.setScale(2);
                                        mapMile.Act_Amt_Wei__c = mapMile.Actual_Amount__c * probability;
                                    }
                                    if(mapMile.Milestone_Date__c <= amortCurrentDate && mapMile.Projected_Amount__c == null ) {
                                        mapMile.Projected_Amount__c = amountPerMonthActual.setScale(2);
                                        mapMile.Proj_Amt_Wei__c = mapMile.Projected_Amount__c * probability;
                                    }
                                    if(isMultiCurrencyEnabled) {
                                        if(mapMile.Amount__c != null) {
                                            mapMile.Converted_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), mapMile.Amount__c)).replace('<br/>', '');    
                                            mapMile.Cor_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), mapMile.Amount__c));    
                                        } else {
                                            mapMile.Converted_Amount__c = Oppty.get('REVvue_CurrencyType__c ') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                                            mapMile.Cor_Amt__c = 0.00;  
                                        } if(mapMile.Actual_Amount__c != null) {
                                            mapMile.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), mapMile.Actual_Amount__c)).replace('<br/>', '');    
                                            mapMile.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), mapMile.Actual_Amount__c));    
                                       } else {
                                            mapMile.Converted_Actual_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                                            mapMile.Cor_Act_Amt__c = 0.00; 
                                        } 
                                        if(mapMile.Projected_Amount__c != null) {
                                            mapMile.Converted_Sales_Manual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), mapMile.Projected_Amount__c)).replace('<br/>', '');    
                                            mapMile.Cor_Prj_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), mapMile.Projected_Amount__c));    
                                        } else {
                                            mapMile.Converted_Sales_Manual_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                                            mapMile.Cor_Prj_Amt__c = 0.00; 
                                        }
                                    } listMileStone.add(mapMile);   
                                } 
                            }                    
                        }     
                        //Checking for Id Null
                        if(overrideRules[i].Id == null) 
                            listMileStone = productMilestones;
                        else {
                            if(!overrideRules[i].AM_Manual_Cal__c && listMileStone == null)
                                listMileStone.addAll(mapMileStonesToBeInserted.values()); 
                            else 
                                 listMileStone = productMilestones;
                        }  
                        string ret = RecognizeForAmortizeMilestones(sequence, recognizableTotal, overrideRules[i].Milestone_Type__c, lineItems[i], revrecLineItems[i], listMileStone, revenuSchedules, oppty, residualTotal, totalRev, oppty.CloseDate, overrideRules[i].Id, overrideRules[i].Divide_By__c);
                        if (ret.length() != 0) 
                            msg += ret + ' for ' + revReclineItems[i].ProductName__c;   
                            
                        //Calling method to calc remaining amount, remaining percent, remaining qty
                        utilHelper.rrliRemainingCalc(lineItems[i],revreclineItems[i], listMileStone, overrideRules[i].Milestone_Type__c, recognizableTotal);
                    }
                } 
            }
            /***** 5. Rule Type = 'Blended Revenue' ******/
            /** ~~~~~~~~~~~~ Blended Revenue Recognition Calculation Start ~~~~~~~~~~~~ **/
            //Code added - 06/17/2015 - As per Blended Recognition Revenue
            else if(overrideRules[i].Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
                List<RevRecProductRuleCategory__c> revRecProductRuleCategories = new List<RevRecProductRuleCategory__c>();
                Date actualStartDate;Date actualEndDate;Date todayDate = Date.Today();Integer startDateMonth;
                Integer startDateYear;Integer endDateMonth;Integer endDateYear;Integer endDateDay;Date transDate;
                Integer currentYear;Integer currentMonth;Integer startDateDay;Integer startDateYearValue;String allCatNames  = '';
                Integer currentDateYearValue;Decimal deferredAmount;Decimal actualTotalRecognized = 0.00;Integer currentDay;
                //Checking for map size and get all product category related to line item
                //Check from here for map 
                if(mapLineItemWithProductCategory != null && mapLineItemWithProductCategory.size() > 0 && mapLineItemWithProductCategory.containsKey(lineItems[i].Id)) { 
                    revRecProductRuleCategories = mapLineItemWithProductCategory.get(lineItems[i].Id) != null ? mapLineItemWithProductCategory.get(lineItems[i].Id) : null;
                    deferredAmount = lineItems[i].TotalPrice;
                    actualTotalRecognized = 0.00;
                }  
                //Checking for list size
                if(revRecProductRuleCategories.size() > 0) {
                    allCatNames = '';  
                    for(RevRecProductRuleCategory__c revCategory : revRecProductRuleCategories){
                        if(!allCatNames.contains(revCategory.Name))
                            allCatNames += revCategory.Name + ',';
                    }
                    allCatNames = allCatNames.removeEnd(',');Integer sequence = 1; 
                    for(RevRecProductRuleCategory__c revCategory : revRecProductRuleCategories){
                            //Creating string to get the category Names
                            String categoryName =  revCategory.Name;
                            //Total category amount  
                            Decimal categoryTotalAmount = (revCategory.Recognized_Amount__c != null ? revCategory.Recognized_Amount__c : 0.00 )+ (revCategory.Actual_Deferred__c != null ? revCategory.Actual_Deferred__c : 0.00);
                            
                            revreclineItems[i].Allocated__c = (revreclineItems[i].Allocated__c != null ? revreclineItems[i].Allocated__c + categoryTotalAmount : categoryTotalAmount); 

                            //Checking for start date not null
                            if(revCategory.Actual_Start_Date__c != null) {
                                actualStartDate = revCategory.Actual_Start_Date__c;
                                startDateYear = actualStartDate.Year();
                                startDateMonth = actualStartDate.Month();
                                startDateDay = actualStartDate.day();
                                startDateYearValue = startDateYear + 1;
                            }

                            //Checking for end date not null
                            if(revCategory.Actual_End_Date__c != null) { 
                                actualEndDate = revCategory.Actual_End_Date__c;
                                endDateMonth = actualEndDate.Month();
                                endDateYear = actualEndDate.Year();
                                endDateDay = actualEndDate.day();
                            }
                            String mapKey;currentYear = todayDate.year();currentMonth = todayDate.Month();currentDay = todayDate.day();
                            currentDateYearValue = currentYear+1;
                            //Checking for Opportunity close date is greater than Dates
                            if(theSetting.Is_Closed_Date_Validation__c)  {
                                if(oppty.CloseDate > actualStartDate ) 
                                    return constants.ERROR_MESSAGE_BASED_ON_DATES;
                                else if(oppty.CloseDate > actualEndDate)
                                    return constants.ERROR_MESSAGE_BASED_ON_DATES;
                            }

                            //Checking for the date difference Added on 13 sept
                             if(actualStartDate != null && actualEndDate != null) {
                                if(utilHelper.yearDifference(actualStartDate, actualEndDate) > 10)
                                    return constants.START_END_DATE_RANGE_EXCEED;
                             }
                            //Checking if recognition type is SINGLE TRANSACTION
                            if(revCategory.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                                //Checking if start date is less than or equals to today
                                if(todayDate >= actualStartDate) {
                                    //Map key
                                    mapKey = lineItems[i].Id + ' - '+string.ValueOf(startDateMonth) + ' - ' +  string.ValueOf(startDateYear);
                                    
                                    //Checking if map contains Key and populate map
                                    if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = revCategory.Recognized_Amount__c, Deferred_Amount__c = 0.00));
                                    else
                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = revCategory.Recognized_Amount__c, Deferred_Amount__c = 0.00)});
                                    //Checking for map contians key 
                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += revCategory.Recognized_Amount__c;
                                        if(LineItems[i].TotalPrice == 0)
                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                        else
                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - revCategory.Recognized_Amount__c;
                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += revCategory.Recognized_Amount__c;
                                        //deferred amount
                                        deferredAmount = deferredAmount - revCategory.Recognized_Amount__c;
                                        actualTotalRecognized += revCategory.Recognized_Amount__c;
                                    } else {
                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(startDateMonth), 
                                            Sequence__c = sequence, Date__c = revCategory.Actual_Start_Date__c, OriginalDate__c = revCategory.Actual_Start_Date__c,
                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c, OpportunityLineItemId__c = lineItems[i].Id, 
                                            RecognizedRev__c = revCategory.Recognized_Amount__c, ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((revCategory.Recognized_Amount__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                            DeferredRev__c = deferredAmount - revCategory.Recognized_Amount__c, RecognizedRevTotal__c = revCategory.Recognized_Amount__c, 
                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));                                        
                                            sequence++; //Increse sequece
                                            //Deferred amount
                                            deferredAmount = deferredAmount - revCategory.Recognized_Amount__c;
                                            actualTotalRecognized += revCategory.Recognized_Amount__c;
                                     }
                                }else { // In case of future date
                                    //Map key
                                    mapKey = lineItems[i].Id + ' - '+string.ValueOf(startDateMonth) + ' - ' +  string.ValueOf(startDateYear);
                                
                                    //Checking if map contains Key and populate map
                                     if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = revCategory.Actual_Deferred__c));
                                     else
                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName, Amount1__c = revCategory.Actual_Deferred__c, Deferred_Amount__c = 0.00)});
                                 
                                    //Checking for map contians key 
                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += revCategory.Actual_Deferred__c;
                                        
                                        if(LineItems[i].TotalPrice == 0)
                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                        else
                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                        
                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c ;
                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += revCategory.Actual_Deferred__c;
                                        deferredAmount = deferredAmount ;
                                    } else {
                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(startDateMonth), 
                                            Sequence__c = sequence, Date__c = revCategory.Actual_Start_Date__c, OriginalDate__c = revCategory.Actual_Start_Date__c,
                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = revCategory.Actual_Deferred__c,
                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((revCategory.Actual_Deferred__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                            DeferredRev__c = deferredAmount , RecognizedRevTotal__c = revCategory.Actual_Deferred__c, 
                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));                                        
                                            sequence++;
                                            deferredAmount = deferredAmount;
                                     }      
                                }
                            //Checking if recognitio type is Amortize
                            }else if(revCategory.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_AMORTIZE) {
                                //Checking if actual start and end date not null
                                if(actualStartDate != null && actualEndDate != null){
                                    //Total months between start and end date
                                    Integer totalMonths = actualStartDate.MonthsBetween(actualEndDate);
                                    Date tempDate = actualStartDate.addMonths(totalMonths);
                                    //Checking for total months
                                    if(tempDate.daysBetween(actualEndDate) >= 0)
                                        totalMonths = totalMonths+1;
                                    if(totalMonths == 0)
                                        totalMonths =1;
                                    //Month Difference between 
                                    Boolean inCurrentMonth = IsInCurrentMonthForBlended(actualStartDate);
                                    transDate = getTransDateForBlended(actualStartDate , inCurrentMonth);
                                    Integer transDay = transDate.day(); 
                                    startDateDay = transDay;
                                    endDateDay = transDay;
                                    //Decimal recognized amount per Month 
                                    Decimal recognizedPerMonth = 0.00;
                                    if(totalMonths == 0)
                                        recognizedPerMonth = 0.00;
                                    else
                                        recognizedPerMonth = (revCategory.Recognized_Amount__c + revCategory.Actual_Deferred__c)/(totalMonths);
                                    List<Decimal> recognizableForEachMonthsForBR = new List<Decimal>();
                                    recognizableForEachMonthsForBR = utilHelper.getRecognigibleFORBR(actualStartDate, actualEndDate, overrideRules[i], 
                                                                                  (revCategory.Recognized_Amount__c + revCategory.Actual_Deferred__c), totalMonths, 
                                                                                   recognizableForEachMonthsForBR);
                                    
                                    if(mapRecognizableForEachMonthsForBR.containsKey(lineItems[i].Id + '-' + revCategory.Name))
                                        mapRecognizableForEachMonthsForBR.get(lineItems[i].Id + '-' + revCategory.Name).addAll(recognizableForEachMonthsForBR);
                                    else
                                        mapRecognizableForEachMonthsForBR.put(lineItems[i].Id + '-' + revCategory.Name, recognizableForEachMonthsForBR);
                                    
                                    //Calculation for Recoggnized Amount - Start 
                                    /** Condition -1 - Checking if Start date less than today and end date greater than today **/
                                    if(todayDate >= actualStartDate && todayDate < actualEndDate) {
                                        //If todya date is greater than Start date
                                        if(todayDate > actualStartDate ) { 
                                            //Checking for Year differnce greater than 1 Like Start date 2012 - today 2015
                                            if(currentYear - startDateYear > 1) {
                                                //Schedule for startDate year
                                                for(integer r = startDateMonth; r <= 12; r++) {
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        startDateDay = Date.daysInMonth(startDateYear, r);
                                                    //Creating key of map
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' + string.valueOf(startDateYear);
                                                    //Checking if map contains Key and populate map
                                                    if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                    else 
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) { 
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        if(lineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }  
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(startDateYear, r, startDateDay), 
                                                            OriginalDate__c = date.newInstance(startDateYear, r, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c =  recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                    
                                                        //Sequence and deferred amount
                                                        sequence ++; 
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }                                               
                                                }
                                                    
                                                //Schedule for intermediate years (Intermeidate months)
                                                for(Integer k=1; k<= (currentYear - startDateYear); k++) {
                                                   if(startDateYearValue < currentYear) {
                                                        //Loop over 12 months
                                                        for(Integer l=1; l<=12;l++) {
                                                            if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                                startDateDay = Date.daysInMonth(startDateYear, l);
                                                            //Map key
                                                            mapKey = lineItems[i].Id + ' - '+string.valueOf(l) + ' - ' + string.valueOf(startDateYearValue);
                                                            //Checking if map contains Key and populate map
                                                            if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                                mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                            else
                                                                mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                             //Category amount
                                                             categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                     
                                                            //Checking for map contians key
                                                            if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                                
                                                                if(LineItems[i].TotalPrice == 0)
                                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                                else
                                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                                
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                                //deferred amount
                                                                deferredAmount = deferredAmount - recognizedPerMonth;
                                                                actualTotalRecognized += recognizedPerMonth;
                                                            }
                                                            else {
                                                                mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(l), 
                                                                    Sequence__c = sequence, Date__c = date.newInstance(startDateYearValue, l, startDateDay), 
                                                                    OriginalDate__c = date.newInstance(startDateYearValue, l, startDateDay),
                                                                    RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                                    OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                                    Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                                    DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                                    ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                                    Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                                
                                                                //Sequence and deferred amount
                                                                sequence ++;
                                                                deferredAmount = deferredAmount - recognizedPerMonth;
                                                                actualTotalRecognized += recognizedPerMonth;
                                                            }
                                                        }
                                                    }
                                                    startDateYearValue ++;
                                                }
                                                
                                                //Schedule Current year
                                                for(Integer j =1; j<= currentMonth; j++) {
                                                    
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        startDateDay = Date.daysInMonth(startDateYear, j);
                                                    
                                                    //Creating Map Key
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(currentYear);
                                                    
                                                     //Checking if map contains Key and populate map
                                                    if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                    else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                      
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                 
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        
                                                        if(LineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        //Deferred amount
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(currentYear, j, startDateDay),OriginalDate__c = date.newInstance(currentYear, j, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        
                                                        if(j == currentMonth && transDate.day() > currentDay) 
                                                            actualTotalRecognized += 0.00;
                                                        else
                                                            actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                }
                                            }
                                            
                                            //Checking IF Year difference  is 1 Year 2015 - 2014
                                            else if(currentYear - startDateYear == 1) { 
                                                 
                                                 //Loop for start date year
                                                for(integer r = startDateMonth; r <= 12; r++) {
                                                    
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        startDateDay = Date.daysInMonth(startDateYear, r);
                                                    
                                                    //Creating map key
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' +  string.valueOf(startDateYear);
                                                        
                                                    //Checking if map contains Key and populate map
                                                    if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                     else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                    
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                     //Checking for map contians key and put values to the same schedule
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        if(LineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        //Deferred Amount
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                    else {
                                                          mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(startDateYear, r, startDateDay) ,OriginalDate__c = date.newInstance(startDateYear, r, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                }
                                                //Loop for today  year
                                                 for(Integer j =1; j<=currentMonth; j++) {
                                                    
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        startDateDay = Date.daysInMonth(startDateYear, j);
                                                    
                                                    //Creating Map Key
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' +  string.valueOf(currentYear);
                                                
                                                    //Checking if map contains Key and populate map
                                                    if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                    else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                     
                                                     //Category amount
                                                     categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;        
                                                                            
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {                                                    
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c +=  recognizedPerMonth;
                                                        
                                                        if(LineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        //Deferred amount
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                    else {
                                                        
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(currentYear, j, startDateDay) ,OriginalDate__c = date.newInstance(currentYear, j, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                            
                                                        //Sequence and Deferred Amount  
                                                        sequence ++; 
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        
                                                        if(j == currentMonth && transDate.day() > currentDay) 
                                                            actualTotalRecognized += 0.00;
                                                        else
                                                            actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                 }
                                            }
                                            
                                            //Same Year - 2015-2015
                                            else if(currentYear - startDateYear == 0) {
                                                
                                                //loop over month between start and end date
                                                 for(Integer j= startDateMonth; j<=currentMonth; j++) {
                                                    
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        startDateDay = Date.daysInMonth(startDateYear, j);
                                                   
                                                    //Creating Map Key 
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(startDateYear);
                                                  
                                                    //Checking if map contains Key and populate map
                                                    if(mapMonthYearScheduleCategories.containsKey(mapKey)) 
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                    else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                    
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                        
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c =  mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        if(LineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                        else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        //Deferred amount
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                        actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(currentYear, j, startDateDay) ,OriginalDate__c = date.newInstance(currentYear, j, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c =  deferredAmount - recognizedPerMonth, RecognizedRevTotal__c =  recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and Deferred amount
                                                        sequence ++;  
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                     
                                                         if(j == currentMonth && transDate.day() > currentDay) 
                                                            actualTotalRecognized += 0.00;
                                                        else
                                                            actualTotalRecognized += recognizedPerMonth;
                                                    }
                                                 }
                                            } 
                                        }
                                      
                                        //Schedule foer deferred amount for 2013-2016
                                        if(todayDate < actualEndDate) {
                                            //Checking for Year differnce greater than 1 Like Start date 2012 - today 2015
                                            if(endDateYear - currentYear  > 1) {
                                                //Schedule for current year
                                                for(integer r = currentMonth + 1; r <= 12; r++) {
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        endDateDay = Date.daysInMonth(startDateYear, r);
                                                    
                                                    //Creating key of map
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' + string.valueOf(currentYear);
                                                    
                                                     //Checking if map contains Key and populate map
                                                     if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                     else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                     
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        if(LineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = ((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity;
                                                        
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(currentYear, r, startDateDay), 
                                                            OriginalDate__c = date.newInstance(currentYear, r, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c =recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;    
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                }
                                                
                                                //Schedule for intermediate years
                                                //Intermeidate months
                                                for(Integer k=1; k<= (endDateYear - currentYear); k++) {
                                                    
                                                     if(currentDateYearValue < endDateYear) {
                                                        
                                                        //Loop over 12 months
                                                        for(Integer l=1; l<=12;l++) {
                                                            
                                                            if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                                endDateDay = Date.daysInMonth(startDateYear, l);
                                                            
                                                            //Creating map key
                                                            mapKey = lineItems[i].Id + ' - '+string.valueOf(l) + ' - ' + string.valueOf(currentDateYearValue);
                                                            
                                                            //Checking if map contains Key and populate map
                                                            if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                                mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                            else
                                                                mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                             
                                                            //Category amount
                                                            categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                            
                                                            //Checking for map contians key
                                                            if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                                
                                                                if(LineItems[i].TotalPrice == 0)
                                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                                else
                                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                                
                                                                //Deferred amount
                                                                deferredAmount = deferredAmount - recognizedPerMonth;
                                                            }
                                                            else {
                                                                mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(l), 
                                                                    Sequence__c = sequence, Date__c = date.newInstance(currentDateYearValue, l, startDateDay), 
                                                                    OriginalDate__c = date.newInstance(currentDateYearValue, l, startDateDay),
                                                                    RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                                    OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                                    DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                                    Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                                    ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                                    Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                                
                                                                //Sequence and deferred amount
                                                                sequence ++;
                                                                deferredAmount = deferredAmount - recognizedPerMonth;
                                                            }
                                                        }
                                                    }
                                                    currentDateYearValue ++;
                                                }
                                                    
                                                //Total months between start and end date
                                                endDateMonth = endDateMonth - 1;
                                                Integer totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                                tempDate = actualStartDate.addMonths(totalMonthsBW);
                                                //Checking for total months
                                                if(tempDate.daysBetween(actualEndDate) >= 0)
                                                    endDateMonth = endDateMonth+1;
                                                //Schedule end year year
                                                for(Integer j =1; j<= endDateMonth; j++) {
                                                    
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        endDateDay = Date.daysInMonth(startDateYear, j);
                                                    
                                                    //Creating map key
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(endDateYear);
                                                    
                                                     //Checking if map contains Key and populate map
                                                     if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                     else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                      
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                   //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                      
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        
                                                        if(LineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;  
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        //Deferred amount
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                            Sequence__c = sequence,
                                                            Date__c =  date.newInstance(endDateYear, j, endDateDay),
                                                            OriginalDate__c =  date.newInstance(endDateYear, j, endDateDay) ,
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                }
                                            }
                                           
                                            //Checking IF Year difference  is 1 Year 2015 - 2014
                                            else if(endDateYear - currentYear  ==  1) {
                                              
                                                 //Loop for current  year
                                                for(integer r = (currentMonth+1); r <= 12; r++) {
                                                    
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        startDateDay = Date.daysInMonth(startDateYear, r);
                                                    
                                                    //Creating map key
                                                    mapKey = lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' +  string.valueOf(currentYear);
                                                                                                 
                                                    //Checking if map contains Key and populate map
                                                    if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                    else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                     
                                                     //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        
                                                        if(lineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        //Deferred amount
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                            Sequence__c = sequence, Date__c = date.newInstance(currentYear, r, startDateDay) ,OriginalDate__c = date.newInstance(currentYear, r, startDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                }
                                                
                                                //Total months between start and end date
                                                endDateMonth = endDateMonth - 1;
                                                Integer totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                                tempDate = actualStartDate.addMonths(totalMonthsBW);
                                                   
                                                //Checking for total months
                                                if(tempDate.daysBetween(actualEndDate) >= 0)
                                                    endDateMonth = endDateMonth+1;
                                           
                                                //Loop for end date  year
                                                 for(Integer j =1; j<=endDateMonth; j++) {
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        endDateDay = Date.daysInMonth(endDateYear, j);
                                                    //Creating map key
                                                    mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' +  string.valueOf(endDateYear);
                                                   
                                                     //Checking if map contains Key and populate map
                                                     if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                     else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                    
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                     //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                      
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        
                                                        if(lineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                    else {
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                            Sequence__c = sequence, 
                                                            Date__c = date.newInstance(endDateYear, j, endDateDay) ,
                                                            OriginalDate__c = date.newInstance(endDateYear, j, endDateDay),
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }                                        
                                                 }
                                            }
                                                
                                            //Same Year - 2015-2015
                                            else if(endDateYear - currentYear == 0) {
                                                
                                                 //Total months between start and end date
                                                endDateMonth = endDateMonth - 1;
                                                Integer totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                                tempDate = actualStartDate.addMonths(totalMonthsBW);
                                                
                                                //Checking for total months
                                                if(tempDate.daysBetween(actualEndDate) >= 0)
                                                    endDateMonth = endDateMonth+1;
                                                
                                                //loop over month between start and end date
                                                 for(Integer j= currentMonth+1; j<=endDateMonth; j++) { 
                                                     
                                                    if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                        endDateDay = Date.daysInMonth(startDateYear, j);
                                                    
                                                    //Creating map key 
                                                    mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(currentYear);
                                                                                                    
                                                     //Checking if map contains Key and populate map
                                                     if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                        mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                     else
                                                        mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                     
                                                    //Category amount
                                                    categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                    //Checking for map contians key
                                                    if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                            
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                        
                                                        if(lineItems[i].TotalPrice == 0)
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                        else
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                        
                                                        //Deferred amount
                                                        deferredAmount =deferredAmount - recognizedPerMonth;
                                                    }
                                                    else {
                                                        
                                                        mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                            Sequence__c = sequence, 
                                                            Date__c =  date.newInstance(currentYear, j, endDateDay)  ,
                                                            OriginalDate__c =  date.newInstance(currentYear, j, endDateDay) ,
                                                            RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                            OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                            Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                            DeferredRev__c = deferredAmount - recognizedPerMonth , RecognizedRevTotal__c = recognizedPerMonth, 
                                                            ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                            Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)); 
                                                        
                                                        //Sequence and deferred amount
                                                        sequence ++;  
                                                        deferredAmount = deferredAmount - recognizedPerMonth;
                                                    }
                                                 }
                                            }                                   
                                        }
                                    }
                                    
                                    /**Condition - 2 - If strat date and end date smaller than current date**/
                                    else if(actualStartDate <= todayDate && actualEndDate <= todayDate && actualStartDate <= actualEndDate) {
                                        
                                        //Integer totalMonths between startDate and Today's date
                                        Integer totalMonthsBWStartAndEndDate ; 
                                    
                                        //Total months between start and end date
                                        endDateMonth = endDateMonth - 1;
                                        Integer totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                        tempDate = actualStartDate.addMonths(totalMonthsBW);
                                        
                                        //Checking for total months
                                        if(tempDate.daysBetween(actualEndDate) >= 0)
                                            endDateMonth = endDateMonth+1;
                                            
                                        //If Difference between start and end date year is = Like 2015-2015
                                        if(endDateYear - startDateYear == 0) {
                                            
                                            //loop over month between start and end date
                                             for(Integer j= startDateMonth; j<=endDateMonth; j++) {
                                                
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    startDateDay = Date.daysInMonth(startDateYear, j);
                                                
                                                //Creating map key Month - Year
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(startDateYear);
                                               
                                                 //Checking if map contains Key and populate map
                                                 if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                 else
                                                    mapMonthYearScheduleCategories.put(mapKey , new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(startDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(startDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                    
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    
                                                    if(j == currentMonth && transDate.day() > currentDay) 
                                                        actualTotalRecognized += 0.00;
                                                    else
                                                        actualTotalRecognized += recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                        Sequence__c = sequence,
                                                        Date__c =  date.newInstance(startDateYear, j, endDateDay),
                                                        OriginalDate__c = date.newInstance(startDateYear, j, endDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c =  recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                    
                                                    //Sequence and deferred amount
                                                    sequence ++;  
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    
                                                    if(j == currentMonth && transDate.day() > currentDay) 
                                                        actualTotalRecognized += 0.00;
                                                    else
                                                        actualTotalRecognized += recognizedPerMonth;
                                                }
                                             }
                                        }
                                        
                                        //If Year difference between start and end is = 1 Like 2015 - 2014
                                        else if(endDateYear - startDateYear  ==  1) {
                                            
                                             //Loop for start Date year
                                            for(integer r = startDateMonth; r <= 12; r++) {
                                                
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    startDateDay = Date.daysInMonth(startDateYear, r);
                                                    
                                                //Creating map key
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' +  string.valueOf(startDateYear);
                                                  
                                                //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth, Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    actualTotalRecognized += recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                        Sequence__c = sequence, Date__c = date.newInstance(startDateYear, r, startDateDay) ,OriginalDate__c = date.newInstance(startDateYear, r, startDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                               
                                                    //Sequence and deferred amount
                                                    sequence ++;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    actualTotalRecognized += recognizedPerMonth;
                                                }
                                            }
                                           
                                            //Loop for end date  year
                                             for(Integer j =1; j<=endDateMonth; j++) {
                                                   
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    endDateDay = Date.daysInMonth(startDateYear, j);
                                                
                                                //Creating the map key
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' +  string.valueOf(endDateYear);
                                                
                                                //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c =  mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    
                                                    //Deferred amount
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    if(j == currentMonth && transDate.day() > currentDay) 
                                                        actualTotalRecognized += 0.00;
                                                    else
                                                        actualTotalRecognized += recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                        Sequence__c = sequence, 
                                                        Date__c = date.newInstance(endDateYear, j, endDateDay)  ,
                                                        OriginalDate__c = date.newInstance(endDateYear, j, endDateDay) ,
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c =  recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                    
                                                    //Sequence and deferred amount
                                                    sequence ++;   
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    
                                                    if(j == currentMonth && transDate.day() > currentDay) 
                                                        actualTotalRecognized += 0.00;
                                                    else
                                                        actualTotalRecognized += recognizedPerMonth;
                                                }                                     
                                             }
                                        }
                                        //Checking for Year differnce greater than 1 year Like 2015 - 2017
                                        if(endDateYear - startDateYear  > 1) {
                                            
                                            //Schedule for start date Year
                                            for(integer r = startDateMonth; r <= 12; r++) {
                                               
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                   startDateDay = Date.daysInMonth(startDateYear, r);
                                                
                                                //Creating key of map
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' + string.valueOf(startDateYear);
                                                
                                                //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});                                              
                                                
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                     
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c  += recognizedPerMonth;
                                                    
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    actualTotalRecognized += recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                        Sequence__c = sequence, Date__c = date.newInstance(startDateYear, r, startDateDay), 
                                                        OriginalDate__c = date.newInstance(currentYear, r, startDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                    
                                                    //Sequence and deferred amount
                                                    sequence ++; 
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    actualTotalRecognized += recognizedPerMonth;
                                                }   
                                            }
                                            
                                            //Schedule for intermediate years
                                            //Intermeidate months
                                            for(Integer k=1; k<= (endDateYear - startDateYear); k++) {
                                                
                                                //Chcking for currentt year
                                                if(startDateYearValue < endDateYear) {
                                                    
                                                    //Loop over 12 months
                                                    for(Integer l=1; l<=12;l++) {
                                                        
                                                        if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                            startDateDay = Date.daysInMonth(startDateYear, l);
                                                        
                                                        //Creating map key
                                                        mapKey =  lineItems[i].Id + ' - '+string.valueOf(l) + ' - ' + string.valueOf(startDateYearValue);
                                                        
                                                         //Checking if map contains Key and populate map
                                                        if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                            mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                        else
                                                            mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                        
                                                        //Category amount
                                                        categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                    
                                                        //Checking for map contians key
                                                        if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) { 
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                            
                                                            if(lineItems[i].TotalPrice == 0)
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                            else
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                            //Deferred amount
                                                            deferredAmount = deferredAmount - recognizedPerMonth;
                                                            actualTotalRecognized += recognizedPerMonth;
                                                        }
                                                        else {
                                                            mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(l), 
                                                                Sequence__c = sequence, Date__c = date.newInstance(startDateYearValue, l, startDateDay), 
                                                                OriginalDate__c = date.newInstance(currentDateYearValue, l, startDateDay),
                                                                RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                                OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                                Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                                DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                                ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                                Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                            
                                                            //Sequence and Deferred amount
                                                            sequence ++; 
                                                            deferredAmount = deferredAmount - recognizedPerMonth;
                                                            actualTotalRecognized += recognizedPerMonth;
                                                        } 
                                                    }
                                                }
                                                startDateYearValue ++;
                                            }
                                            //Total months between start and end date
                                            endDateMonth = endDateMonth - 1;
                                            totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                            tempDate = actualStartDate.addMonths(totalMonthsBW);
                                            
                                            //Checking for total months
                                            if(tempDate.daysBetween(actualEndDate) >= 0)
                                                endDateMonth = endDateMonth+1;
                                            
                                            //Schedule end year year 
                                            for(Integer j =1; j<= endDateMonth; j++) {
                                                
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    endDateDay = Date.daysInMonth(startDateYear, j);
                                                
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(endDateYear);
                                                  
                                                //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                     
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth; 
                                                                       
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c +=  recognizedPerMonth;
                                                    
                                                    //Deferred amount
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                    if(j == currentMonth && transDate.day() > currentDay) 
                                                        actualTotalRecognized += 0.00;
                                                    else
                                                        actualTotalRecognized += recognizedPerMonth;
                                                }
                                                else { 
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                        Sequence__c = sequence, 
                                                        Date__c =  date.newInstance(endDateYear, j, endDateDay) ,
                                                        OriginalDate__c =  date.newInstance(endDateYear, j, endDateDay) ,
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c =  recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                    
                                                     //Sequnce and deferrred amount
                                                     sequence ++;
                                                     deferredAmount = deferredAmount - recognizedPerMonth;
                                                     if(j == currentMonth && transDate.day() > currentDay) 
                                                        actualTotalRecognized += 0.00;
                                                     else
                                                        actualTotalRecognized += recognizedPerMonth;
                                                }
                                            }
                                        }
                                    }
                                    
                                    /**Condition 3 - If strat date and end date greater than current date**/
                                    else if(actualStartDate > todayDate && actualEndDate > todayDate && actualStartDate <= actualEndDate) {
                                        
                                        //Integer totalMonths between startDate and Today's date
                                        Integer totalMonthsBWStartAndEndDate ; 
                                        //Total montths between
                                        totalMonthsBWStartAndEndDate = actualStartDate.MonthsBetween(actualEndDate);
                                        //Total months between start and end date
                                        endDateMonth = endDateMonth - 1;
                                        Integer totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                        tempDate = actualStartDate.addMonths(totalMonthsBW);
                                        //Checking for total months
                                        if(tempDate.daysBetween(actualEndDate) >= 0)
                                            endDateMonth = endDateMonth+1;
                                    
                                        //If Difference between start and end date year is = Like 2015-2015
                                        if(endDateYear - startDateYear == 0) {
                                            //loop over month between start and end date
                                             for(Integer j= startDateMonth; j<=endDateMonth; j++) {
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                   endDateDay = Date.daysInMonth(startDateYear, j);
                                                //Creating map key Month - Year
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(startDateYear);
                                                
                                                //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                   
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(startDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(startDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c +=  recognizedPerMonth;
                                                    
                                                    //Deferred amount
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                        Sequence__c = sequence, 
                                                        Date__c =  date.newInstance(startDateYear, j, endDateDay) ,
                                                        OriginalDate__c =  date.newInstance(startDateYear, j, endDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                
                                                    //Sequence and deferred amount
                                                    sequence ++;
                                                    deferredAmount = deferredAmount - recognizedPerMonth; 
                                                } 
                                            }
                                        }
                                        
                                        //If Year difference between start and end is = 1 Like 2015 - 2014
                                        else if(endDateYear - startDateYear  ==  1) {
                                            
                                             //Loop for start Date year
                                            for(integer r = startDateMonth; r <= 12; r++) {
                                                
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    startDateDay = Date.daysInMonth(startDateYear, r);
                                                
                                                //Creating map key
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' +  string.valueOf(startDateYear);
                                                      
                                                 //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                 
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                
                                                 //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    //Deferred amount
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                        Sequence__c = sequence, Date__c = date.newInstance(startDateYear, r, startDateDay) ,OriginalDate__c = date.newInstance(startDateYear, r, startDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                
                                                    //Sequence and deferred amount
                                                    sequence ++;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                            }                                            
                                            //Loop for end date  year
                                             for(Integer j =1; j<=endDateMonth; j++) {
                                                
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    endDateDay = Date.daysInMonth(startDateYear, j);
                                                
                                                //Creating map key
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' +  string.valueOf(endDateYear);
                                                
                                                 //Checking if map contains Key and populate map
                                                 if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                     mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth; 
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                        Sequence__c = sequence, 
                                                        Date__c = date.newInstance(endDateYear, j, endDateDay)  ,
                                                        OriginalDate__c =  date.newInstance(endDateYear, j, endDateDay) ,
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                
                                                    //Sequence and deferred amount
                                                    sequence ++; 
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }                                       
                                             }
                                        }
                                        //Checking for Year differnce greater than 1 year Like 2015 - 2017
                                        if(endDateYear - startDateYear  > 1) {
                                            
                                            //Schedule for start date Year
                                            for(integer r = startDateMonth; r <= 12; r++) {
                                                
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    startDateDay = Date.daysInMonth(startDateYear, r);
                                                
                                                //Creating key of map
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(r) + ' - ' + string.valueOf(startDateYear);
                                                
                                                 //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                               
                                                //Category amount
                                                categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                
                                                //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                                else {
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(r), 
                                                        Sequence__c = sequence, Date__c = date.newInstance(startDateYear, r, startDateDay), 
                                                        OriginalDate__c = date.newInstance(currentYear, r, startDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                
                                                    //Sequence and deferred amount
                                                    sequence ++; 
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }   
                                            }
                                            
                                            //Schedule for intermediate years
                                            //Intermeidate months
                                            for(Integer k=1; k<= (endDateYear - startDateYear); k++) {
                                                //Checking if end date year is greater than start
                                                if(startDateYearValue < endDateYear) {
                                                    //Loop over 12 months 
                                                    for(Integer l=1; l<=12;l++) {
                                                        if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                            startDateDay = Date.daysInMonth(startDateYear, l);
                                                        //Creating map key
                                                        mapKey =  lineItems[i].Id + ' - '+string.valueOf(l) + ' - ' + string.valueOf(startDateYearValue);
                                                        
                                                         //Checking if map contains Key and populate map
                                                        if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                            mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                        else
                                                            mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName , Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                        
                                                         //Category amount
                                                        categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                
                                                        //Checking for map contians key
                                                        if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                            
                                                            if(lineItems[i].TotalPrice == 0)
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                            else
                                                                mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                            mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                            deferredAmount = deferredAmount - recognizedPerMonth;
                                                        }
                                                        else {
                                                            mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(l), 
                                                                Sequence__c = sequence, Date__c = date.newInstance(startDateYearValue, l, startDateDay), 
                                                                OriginalDate__c = date.newInstance(currentDateYearValue, l, startDateDay),
                                                                RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                                OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                                Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 :(((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                                DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                                ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                                Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                        
                                                            //Sequence and deferred amount
                                                            sequence ++; 
                                                            deferredAmount = deferredAmount - recognizedPerMonth;
                                                        } 
                                                    }
                                                }
                                                startDateYearValue ++;
                                            }
                                            
                                            //Total months between start and end date
                                            endDateMonth = endDateMonth - 1;
                                            totalMonthsBW = actualStartDate.MonthsBetween(actualEndDate);
                                            tempDate = actualStartDate.addMonths(totalMonthsBW);
                                            
                                            //Checking for total months
                                            if(tempDate.daysBetween(actualEndDate) >= 0)
                                                endDateMonth = endDateMonth+1;
                                                
                                            //Schedule end year year 
                                            for(Integer j =1; j<= endDateMonth; j++) { 
                                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                                    endDateDay = Date.daysInMonth(startDateYear, j);                                            
                                                //Creating map key
                                                mapKey =  lineItems[i].Id + ' - '+string.valueOf(j) + ' - ' + string.valueOf(endDateYear);
                                                   
                                                 //Checking if map contains Key and populate map
                                                if(mapMonthYearScheduleCategories.containsKey(mapKey))
                                                    mapMonthYearScheduleCategories.get(mapKey).add(new RevRecScheduleCategory__c(Category_Name__c = categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth));
                                                else
                                                    mapMonthYearScheduleCategories.put(mapKey ,  new List<RevRecScheduleCategory__c>{new RevRecScheduleCategory__c(Category_Name__c =categoryName, Amount1__c = recognizedPerMonth,Deferred_Amount__c = categoryTotalAmount - recognizedPerMonth)});
                                                
                                                //Category amount
                                               categoryTotalAmount = categoryTotalAmount - recognizedPerMonth;
                                                 
                                               //Checking for map contians key
                                                if(mapScheduleAccordingToMonthAndYear.containsKey(mapKey)) {
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).Date__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).OriginalDate__c = date.newInstance(endDateYear, j, endDateDay);
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c += recognizedPerMonth;
                                                    
                                                    if(lineItems[i].TotalPrice == 0)
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = 0;
                                                    else
                                                        mapScheduleAccordingToMonthAndYear.get(mapKey).Recognized_Quantity__c = (((mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRev__c * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100;
                                                        
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c = mapScheduleAccordingToMonthAndYear.get(mapKey).DeferredRev__c - recognizedPerMonth;
                                                    mapScheduleAccordingToMonthAndYear.get(mapKey).RecognizedRevTotal__c += recognizedPerMonth;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                                else { 
                                                    mapScheduleAccordingToMonthAndYear.put(mapKey , new RevRecOpportunityLineItemSchedule__c(Month__c = string.valueOf(j), 
                                                        Sequence__c = sequence, 
                                                        Date__c = date.newInstance(endDateYear, j, endDateDay),
                                                        OriginalDate__c =  date.newInstance(endDateYear, j, endDateDay),
                                                        RevRecOpportunityLineItem__c = lineItems[i].RevRecOpportunityLineItem__c,
                                                        OpportunityLineItemId__c = lineItems[i].Id, RecognizedRev__c = recognizedPerMonth,
                                                        Recognized_Quantity__c = (lineItems[i].TotalPrice == 0 ? 0 : (((recognizedPerMonth * 100)/lineItems[i].TotalPrice) * lineItems[i].Quantity)/100),
                                                        DeferredRev__c = deferredAmount - recognizedPerMonth, RecognizedRevTotal__c = recognizedPerMonth, 
                                                        ResidualAmountTotal__c = residualTotal, LineItemAmountTotal__c = totalRev,
                                                        Categories_List__c = allCatNames, Rule_Type__c = Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
                                                
                                                    sequence ++;
                                                    deferredAmount = deferredAmount - recognizedPerMonth;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                } 
                //Variables 
                Decimal totalAmount = lineItems[i].TotalPrice;
                Decimal totalDeferredAmount;
                Decimal totalRecAmount = 0.00;
                utilHelper.calculateAmountForBR(mapScheduleAccordingToMonthAndYear, mapMonthYearScheduleCategories, mapRecognizableForEachMonthsForBR, /*totalAmount,*/ lineItems[i].Quantity, probability, lineItems);
                actualTotalRecognized = 0.0;
                Date td = Date.Today();
                //Loop over all Blended Schedules and calculate deferred amount again
                for(RevRecOpportunityLineItemSchedule__c sc : mapScheduleAccordingToMonthAndYear.Values()) {
                    
                    //Checking for conditions and then put values   
                    if(sc.RevRecOpportunityLineItem__c == revreclineItems[i].Id) {
                        totalDeferredAmount = 0;
                        if(sc.Date__c <= td)
                            totalRecAmount += sc.RecognizedRev__c;
                        totalDeferredAmount = totalAmount - totalRecAmount;
                        sc.DeferredRev__c = totalDeferredAmount;
                        sc.RecognizedRevTotal__c = totalRecAmount;
                        //Code modified - (28/7/2016) - Check if multi currency enabled then do this
                        if(isMultiCurrencyEnabled)
                            sc.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                    } 
                }     
                utilHelper.rroliScheduleWeightedValues(mapScheduleAccordingToMonthAndYear,probability,revreclineItems[i].Id);
                utilHelper.rrliCalculation(revreclineItems[i],lineItems[i],totalRecAmount,probability,overrideRules[i]);
            }
            //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
            //If true the do this 
            if(isMultiCurrencyEnabled) {
                if(revreclineItems[i].RecognizedRev__c != null) {
                    revreclineItems[i].Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), revreclineItems[i].RecognizedRev__c)).replace('<br/>', '');
                    revreclineItems[i].Cor_Rec_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), revreclineItems[i].RecognizedRev__c));    
                } else {
                    revreclineItems[i].Converted_Recognized_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                    revreclineItems[i].Cor_Rec_Amt__c = 0.00;
                }
                
                //Checking for null 
                if(revreclineItems[i].DeferredRev__c != null) {
                    revreclineItems[i].Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), revreclineItems[i].DeferredRev__c)).replace('<br/>', '');
                    revreclineItems[i].Cor_Def_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), revreclineItems[i].DeferredRev__c));
                } else {
                    revreclineItems[i].Converted_Deferred_Amount__c = oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + oppty.get('CurrencyIsoCode') + ' 0.00 )';
                    revreclineItems[i].Cor_Def_Amt__c = 0.00;
                }
            }
            if(overrideRules[i].Id != null && !overrideRules[i].Is_Default_Overriden__c) {
                
                lineItems[i].Overriden_Rule_Assignment_Id__c = overrideRules[i].Id;
                lineItems[i].Overridden_Rule__c = overrideRules[i].Name;
            }
            
            if((overrideRules[i].Is_Default_Overriden__c && overrideRules[i].Enable_Manual_Forecast__c
                && overrideRules[i].Forecast_With_Zero_Value__c) || overrideRules[i].Man_Ini_To_Zero__c) {
                for(RevRecProductRuleMilestone__c mile : mapMileStonesToBeInserted.values()) {
                    if(mile.RevRecProductRule__c == overrideRules[i].Id) {
                        mile.Actual_Amount__c = 0.00;mile.Projected_Amount__c = 0.00;
                        mile.Act_Amt_Wei__c = 0.00;mile.Proj_Amt_Wei__c =0.00;
                    }
                }
            }
        }
        
        if(isRuleNull)
            msg = Constants.START_RULE_CANNOT_NUll_ERROR_MESSAGE + temp;
        if(isDateNull)
            msg = Constants.START_END_DATE_CANNOT_NUll_ERROR_MESSAGE + temp; 
                                                            
        utilHelper.calMileWithCorporateField(mapMileStonesToBeInserted.values(), oppty, utl);
 
         //Check for list size
         if(mapMileStonesToBeInserted.size() > 0) 
             upsert mapMileStonesToBeInserted.values();
        
        //Add schedule into list 
        revenuSchedules.addAll(mapScheduleAccordingToMonthAndYear.values());
        return msg; 
    }
    
     /** ~~~~~~~~~ Code added - 06/17/2015 - As per Blended Revenue Recognition ~~~~~~~~~ **/
    /**
     *  @description    :   This method is used to calculate the recognized and deferred amount for blended revenue recognition
     *
     *  @return         :   calculateBlended
     * 
     *  @args           :   RevRecProductRuleCategory__c productCategory, Decimal outstandingBalance, Decimal recognizedAmount, 
     *                      Decimal deferredAmount, OpportunityLineItem lineitem, String msg, List<RevRecProductRuleCategory__c> listProductRuleCategories
    **/  
    public static CalculateBlendedWrapper calculateRecAndDeferredRevForBlended (RevRecProductRuleCategory__c productCategory,
                                    Decimal outstandingBalance, Decimal recognizedAmount, Decimal deferredAmount,
                                    OpportunityLineItem lineitem, String msg, List<RevRecProductRuleCategory__c> listProductRuleCategories, 
                                    List<RevRecProductRuleController.ProductRuleCategoryWrapper> prdWrap, Decimal actualDeferred, 
                                    RevRecProductRule__c overrideRules) {

        //Initilize wrapper class
        CalculateBlendedWrapper wrapCal = new CalculateBlendedWrapper(); 
          
        //Variables to handle Amortized rule 
        Integer totalMonths ;
        Date endDateActual ;
        Date startDateActual;
        Decimal amountPerMonth; 
        Decimal amountPerQty ;
        Decimal qtyPerMonth;
        Decimal percentPerMonth;
        Decimal totalAmountForQty ;
        Decimal lineItemAmount;
        Decimal amountToCalculateRecognized;
        Decimal actualCatDifference = 0.00;
          
        //Checiing for null
        if(productCategory != null && !productCategory.Is_Split__c) { 
            
            //Initilize variables
            totalMonths = 0;
            amountPerMonth = 0.00;
            qtyPerMonth = 0.00;
            amountPerQty = 0.00;
            totalAmountForQty = 0.00;
            percentPerMonth = 0.00; 
            amountToCalculateRecognized = 0.00;
            actualCatDifference = 0.00;
            
            //Added on 03/20/2018
            //Variables
            Double totalRev = lineitem.TotalPrice;Double residualTotal = 0;Double recognizedTotal = 0;Double recognizableTotal ;
            Double residualAmount = (overrideRules.Residual_Amount__c == null) ? 0 : overrideRules.Residual_Amount__c ;
            
            if (overrideRules.Residual_Amount_Type__c == 'Percent') 
                residualTotal = (totalRev * residualAmount)/100.0;
            else 
                residualTotal = residualAmount;
            if(totalRev != null)
                recognizableTotal = totalRev;
            if(residualTotal != null)
                recognizableTotal -= residualTotal;
            
            //Checking for Line item Number
            if(String.isNotBlank(productCategory.Line_Item__c)) {
                
                //Calculate Line number
                Integer lineNumber = Integer.ValueOf(productCategory.Line_Item__c) - 1;
                
                //If line item number is 0 , Use Opportunity Line item amount
                if(productCategory.Line_Item__c == '0')
                    amountToCalculateRecognized = lineItem.TotalPrice;
                else {
                   
                    //Checking for Null
                    if(listProductRuleCategories != null && listProductRuleCategories.size() > 0)
                        amountToCalculateRecognized = listProductRuleCategories[lineNumber].Deferred_Amount__c;
                    else if(prdWrap != null)
                        amountToCalculateRecognized = prdWrap[lineNumber].revRecProductCategory.Deferred_Amount__c;
                }
            }
             
            //Calculation for Recognized and Deferred Revenue 
            //1.If Single Transaction
            if(productCategory.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                                     
                //Checking for percent / Qty and Amount and calculate Recognized and Deferred amount
                if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_PERCENT && productCategory.Percent__c != null)
                    recognizedAmount = (amountToCalculateRecognized * productCategory.Percent__c)/100;
                else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_QTY && productCategory.Qty__c != null)
                    recognizedAmount = ((amountToCalculateRecognized)/lineitem.Quantity)* productCategory.Qty__c; 
                else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_AMOUNT && productCategory.Amount__c != null)
                    recognizedAmount = productCategory.Amount__c;
                 
                //Code added on 30 March 2016 - BUG FIX 2016
                actualCatDifference =  recognizedAmount;    
                  
                //Checking for Actual start date
                if(productCategory.Actual_Start_Date__c != null && productCategory.Actual_Start_Date__c <= Date.Today()) {
                    //Deferred amount
                    deferredAmount = (outstandingBalance - recognizedAmount );
                    actualDeferred = 0.00;
                    recognizedAmount = recognizedAmount; 
                }else {
                     //In case of single transaction If no any recognozation yet then deffered amount is set to previous one
                     deferredAmount = (outstandingBalance - recognizedAmount  ); 
                     actualDeferred = (recognizedAmount );
                     recognizedAmount = 0.00; 
                }    
             
            }else if(productCategory.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE) {
                
                //Decimal total Amount
                Decimal totalAmount = 0.00;
                
                //Checking for Amount / Qty and Percent 
                if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_AMOUNT && productCategory.Amount__c != null) {
                    
                    amountPerMonth = productCategory.Amount__c;
                    totalAmount = amountPerMonth;
                }else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_QTY && productCategory.Qty__c != null) {
                    
                    amountPerQty =  amountToCalculateRecognized / lineItem.Quantity;
                    totalAmountForQty = amountPerQty * productCategory.Qty__c;
                    totalAmount = totalAmountForQty;
                }else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_PERCENT && productCategory.Percent__c != null) {
                    
                    percentPerMonth = (productCategory.Percent__c * amountToCalculateRecognized)/ 100;
                    totalAmount = percentPerMonth;
                }
             
                 //Code added on 30 March 2016 - BUG FIX 2016
                actualCatDifference =  totalAmount; 
                deferredAmount = outstandingBalance - totalAmount;
                
                //Checking for Actual start date and Actual end Date Not Null
                if(productCategory.Actual_Start_Date__c != null && productCategory.Actual_End_Date__c != null) {
                    
                    //Getting start and end date from category 
                    startDateActual = productCategory.Actual_Start_Date__c;
                    endDateActual = productCategory.Actual_End_Date__c;
                    
                    //Checking for any of the date not null
                    if(endDateActual != null || startDateActual != null) {
                   
                        //Checking for end date greater than start date  and Getting total months between start and end date
                        if( endDateActual >= startDateActual) {
                        
                            //Added on 03/20/2018
                            RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                            List<Decimal> recognizableForEachMonthsForBR = new List<Decimal>();

                            //Total months
                            totalMonths = Integer.ValueOf(startDateActual.MonthsBetween(endDateActual));
                            totalMonths = utilHelper.getTotalMonths(startDateActual, endDateActual, totalMonths, overrideRules);
                            recognizableForEachMonthsForBR = utilHelper.getRecognigibleFORBR(startDateActual, endDateActual, overrideRules, 
                                                                                             totalAmount, totalMonths, 
                                                                                             recognizableForEachMonthsForBR);
                            
                            //Temp date
                            Date tempDate = startDateActual.addMonths(totalMonths);
                            
                            //Checking for total months
                            if(tempDate.daysBetween(endDateActual) >= 0)
                                totalMonths = totalMonths+1;

                            //Month Difference between
                            Boolean inCurrentMonth = IsInCurrentMonthForBlended(startDateActual);
                            Integer recognizedMonth = 0;
                            Date transDate = GetTransDateForBlended(startDateActual , inCurrentMonth);
                            
                            Integer transDay = transDate.toStartOfMonth().day();
                            Integer transMonth = transDate.month();
                            
                            for(Integer i=1; i<= (totalMonths) ; i++) {
                                if(transDate <= Date.today())
                                    recognizedMonth = recognizedMonth + 1;
                            
                                if(appSetting.Time_of_Month_Selection_Types_tr__c == '1') {
                                    transMonth = transMonth+1;
                                    transDay = Date.daysInMonth(transDate.year(), (transDate.month() +1));
                                    transDate = Date.newInstance(transDate.year(), transMonth, transDay);
                                }  else
                                    transDate = transDate.addMonths(1);
                            }
                            //Checking for months
                            if(totalMonths != null) {
                                if(recognizedMonth > 0) {
                                    
                                    //Calculation for Recognized and deferred
                                    for(Integer count=0; count < recognizedMonth; count++) {
                                        
                                        if(recognizableForEachMonthsForBR.size() > 0) 
                                            recognizedAmount += recognizableForEachMonthsForBR[count];
                                    }   
                                }
                                actualDeferred = (totalAmount - recognizedAmount );
                           }
                        }else {
                            actualDeferred = (totalAmount - recognizedAmount );
                                
                            //Error message to show on page 
                            msg += 'End date must be greater than start Date for Category "' + productCategory.Name + '"'; 
                        } 
                    }else  
                        actualDeferred = (totalAmount - recognizedAmount );
               }else
                    actualDeferred = (totalAmount - recognizedAmount );
            }
        }else {
            outStandingBalance = (outstandingBalance != null ? outstandingBalance : 0.00) - ( (productCategory.Recognized_Amount__c != null ? productCategory.Recognized_Amount__c : 0.00 ) + (productCategory.Actual_Deferred__c != null ? productCategory.Actual_Deferred__c : 0.00));
            actualCatDifference = actualCatDifference != null ? actualCatDifference : 0.00;
            msg = '';
            recognizedAmount = productCategory.Recognized_Amount__c != null  ?  productCategory.Recognized_Amount__c  :  0.00;
            deferredAmount = productCategory.Deferred_Amount__c != null ? productCategory.Deferred_Amount__c : 0.00;
            actualDeferred = productCategory.Actual_Deferred__c != null ? productCategory.Actual_Deferred__c : 0.00 ;
        }
        
        //Populate wrapper
        wrapCal.outStandingBalance = outstandingBalance;
        wrapCal.msg = msg;
        wrapCal.recognizedAmount = recognizedAmount;
        wrapCal.deferredAmount = deferredAmount;
        wrapCal.actualDeferred = actualDeferred;
        wrapCal.actualCatDifference = actualCatDifference;
        return wrapCal;
    }
    
    //calculate all now, if resource problem later on, need change it
    public string EvaluateRevRecScheduleForOpportunity(String theOppId) {
        //String Message
        String msg = '';
        List<RevRecProductRule__c> ruleToUpdate = new List<RevRecProductRule__c>();
        //List to hold line items to be updated
        List<OpportunityLineItem> ruleOnLineItemsToBeUpdated = new List<OpportunityLineItem>();
        
        try { //Try to calculate the oppprtunity according to rule stamped
            
            boolean shouldContinue = true;
            boolean shouldContinueRT = true;
            Set<id> setContractIds = new Set<id>();
            
            Opportunity theOppty; 
            
            if(String.isNotBlank(theOppId) && theOppId != null )            
                theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', theOppId);

            //Checking for null
            if(theOppty != null) {
                
                if(theOppty.contractId != null || theOppty.contractId != '')
                    setContractIds.add(theOppty.contractId);
                
                utl = new Utility(theOppty); 
            }else {
                msg = 'Duplicate fields are present on the Opportunity. Please change the API name of the field' ;
                return msg;
            }
            
            OpportunityStage theStage = null;
            if(theOppty.StageName != null && theOppty.StageName.length() > 0 && mapStageNameWithAllOppStage.containsKey(theOppty.StageName) != null)
                theStage = mapStageNameWithAllOppStage.get(theOppty.StageName);
            
            Set<id> lineItemIds = new Set<id>();
            Set<id> setProduct2Ids = new Set<id>();
            
            List<OpportunityLineItem> allLineItemsForOpportunity = new List<OpportunityLineItem>(); 
            
            //Collection to hold revreclineitem to create if does not exist
            List<RevRecOpportunityLineItem__c> allNewRevRecLineItem = new List<RevRecOpportunityLineItem__c>();
            Map<string, RevRecOpportunityLineItem__c> allRevRecLineItemMap = new Map<string, RevRecOpportunityLineItem__c>();

            if(String.isNotBlank(theOppId) && theOppId != null ) 
                allLineItemsForOpportunity = [SELECT Id, Name, Rule_Assignment__c, PricebookEntry.Name, PricebookEntry.product2.id, 
                                                PricebookEntry.product2.Name, RevRecRule__c,
                                                PricebookEntry.product2.Family,
                                                RevRecRule__r.Name,
                                                RevRecRule__r.Active__c, 
                                                RevRecRule__r.Default_Rule__c, 
                                                RevRecRule__r.Description__c, 
                                                RevRecRule__r.Divide_By__c, 
                                                RevRecRule__r.initial_amount__c, 
                                                RevRecRule__r.initial_amount_type__c, 
                                                RevRecRule__r.Offset_Period__c,  
                                                RevRecRule__r.offset_type__c,
                                                RevRecRule__r.Period__c, 
                                                RevRecRule__r.Period_or_Exact_Days__c, 
                                                RevRecRule__r.Recognition_Type__c, 
                                                RevRecRule__r.Residual_Amount__c, 
                                                RevRecRule__r.Residual_Amount_Type__c, 
                                                RevRecRule__r.Revenue_Recognition_End_Date__c,  
                                                RevRecRule__r.Revenue_Recognition_Start_Date__c,
                                                RevRecRule__r.Milestone_Type__c,
                                                RevRecRule__r.Enable_Manual_Forecast__c,
                                                RevRecRule__r.Forecast_With_Zero_Value__c,
                                                PricebookEntry.product2.RevRecRule__r.Id, 
                                                PricebookEntry.product2.RevRecRule__r.name, 
                                                PricebookEntry.product2.RevRecRule__r.Active__c, 
                                                PricebookEntry.product2.RevRecRule__r.Default_Rule__c, 
                                                PricebookEntry.product2.RevRecRule__r.Description__c, 
                                                PricebookEntry.product2.RevRecRule__r.Divide_By__c, 
                                                PricebookEntry.product2.RevRecRule__r.initial_amount__c, 
                                                PricebookEntry.product2.RevRecRule__r.initial_amount_type__c, 
                                                PricebookEntry.product2.RevRecRule__r.Offset_Period__c,  
                                                PricebookEntry.product2.RevRecRule__r.offset_type__c,
                                                PricebookEntry.product2.RevRecRule__r.Period__c, 
                                                PricebookEntry.product2.RevRecRule__r.Period_or_Exact_Days__c, 
                                                PricebookEntry.product2.RevRecRule__r.Recognition_Type__c, 
                                                PricebookEntry.product2.RevRecRule__r.Residual_Amount__c, 
                                                PricebookEntry.product2.RevRecRule__r.Residual_Amount_Type__c, 
                                                PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_End_Date__c,  
                                                PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_Start_Date__c,
                                                PricebookEntry.product2.RevRecRule__r.Milestone_Type__c,
                                                RevRecOpportunityLineItem__r.Id,
                                                RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
                                                RevRecOpportunityLineItem__r.TotalRev__c,
                                                RevRecOpportunityLineItem__r.DeferredRev__c,
                                                RevRecOpportunityLineItem__r.RecognizedRev__c,
                                                RevRecOpportunityLineItem__r.CalculatedAt__c,
                                                RevRecOpportunityLineItem__r.ResidualAmount__c,
                                                RevRecOpportunityLineItem__r.DefReWei__c,
                                                RevRecOpportunityLineItem__r.RecRevWei__c,
                                                RevRecOpportunityLineItem__r.ResAmtWei__c,
                                                RevRecOpportunityLineItem__r.ProductName__c,
                                                RevRecOpportunityLineItem__r.Opportunity__c,
                                                RevRecOpportunityLineItem__r.Remaining_Qty__c,
                                                RevRecOpportunityLineItem__r.Remaining_Amount__c,
                                                RevRecOpportunityLineItem__r.Remaining_Percentage__c,
                                                RevRecOpportunityLineItem__r.Allocated_Amount__c,
                                                RevRecOpportunityLineItem__r.Rule_Assignment__c,
                                                RevRecOpportunityLineItem__r.RevRecRule__c  ,
                                                RevRecOpportunityLineItem__r.Converted_Recognized_Amount__c,
                                                product2.RevRecRule__c
                                            FROM OpportunityLineItem WHERE  OpportunityId = :theOppId]; 
            
            for(OpportunityLineItem item : allLineItemsForOpportunity) {
                lineItemIds.add(item.id);
                setProduct2Ids.add(item.PricebookEntry.Product2.Id);
                
                //In case if RevRecOpportuntiyLineitem does not exists
                //Check if Opportunity Line Item doesn't exist then create one 
                if(item.RevRecOpportunityLineItem__r.Id == null) {
                    String name;
                    //Check if Product name is morethan 80 character
                    if(item.PricebookEntry.Name.length() > 80)
                        name = item.PricebookEntry.Name.substring(0,79);
                    else
                        name = item.PricebookEntry.Name;
                    RevRecOpportunityLineItem__c revRecLineItem = new RevRecOpportunityLineItem__c(name=name, opportunity__c = theOppId, OpportunityLineItemId__c = item.Id);
                    revRecLineItem.ProductName__c = item.PricebookEntry.Name;
                    revRecLineItem.Product_Family__c = item.PricebookEntry.Product2.Family;
                    allNewRevRecLineItem.add(revRecLineItem);
                }
            }
            
            //Check for size, insert revreclineitems and update RevRecOpportunityLineItem field on OpportunityLineItem with inserted revreclineitem
            if(allNewRevRecLineItem.size() > 0) {
                insert allNewRevRecLineItem;
                
                for (RevRecOpportunityLineItem__c item : allNewRevRecLineItem) 
                    allRevRecLineItemMap.put(item.OpportunityLineItemId__c, item);
                
                for(OpportunityLineItem item : allLineItemsForOpportunity) {
                    RevRecOpportunityLineItem__c rrItem = allRevRecLineItemMap.get(item.Id);
                    if (rrItem != null) 
                        item.RevRecOpportunityLineItem__c = rrItem.Id;
                }
                if(allLineItemsForOpportunity != null)
                    update(allLineItemsForOpportunity);
                
                BY_PASS_REVREC_LINE_ITEM_TRIGGER = true;
            }
            
            if (lineItemIds.size() < 1) {
                
                if(theOppty.REVvue_TotalOpportunity__c != 0.00 || theOppty.REVvue_TotalRecognized__c != 0.00 || 
                    theOppty.REVvue_TotalDeferred__c != 0.00 || theOppty.REVvue_TotalResidual__c != 0.00 || 
                    theOppty.REVvue_TotalForecasted__c != 0.00|| theOppty.REVvue_TotalForecastedwei__c != 0.00) {
                    
                    theOppty.REVvue_TotalOpportunity__c = 0.00; theOppty.REVvue_TotalRecognized__c = 0.00;
                    theOppty.REVvue_TotalResidual__c = 0.00; theOppty.REVvue_TotalDeferredwei__c = 0.00;
                    theOppty.REVvue_Total_Opp_wei__c = 0.00; theOppty.REVvue_TotalRecognizedwei__c = 0.00;
                    theOppty.REVvue_TotalResidualwei__c = 0.00;  theOppty.REVvue_TotalDeferred__c = 0.00;
                    theOppty.REVvue_TotalForecasted__c = 0.00; theOppty.REVvue_TotalForecastedwei__c = 0.00;
                    
                    update theOppty;

                }
                
                msg = 'Revenue allocation/distribution cannot be calculated because this opportunity does not have products';
                return msg;
            }
            
            msg = utilHelper.appSettingChecks(theSetting, theOppty, theStage);
            if(msg != null && msg != 'null' && msg.length() > 0)
                return msg;
 
            List<OpportunityLineItem> itemListWithAllFields = RevRecHelper.GetLineItemListWithAllFieldsByItemSetClone(LineItemIds);
            List<Product2> product2WithAllFields = RevRecHelper.GetProduct2ListWithAllFieldsByItemSetClone(setProduct2Ids);
            List<Contract> contractWithAllFields = new List<Contract>();
            Map<id, OpportunityLineItem> itemListWithAllFieldsMap = new Map<id, OpportunityLineItem> ();
            Map<id, Product2> product2WithAllFieldsMap = new Map<id, Product2> ();
            Map<id, Contract> contractWithAllFieldsMap = new Map<id, Contract> ();
            
            if(setContractIds.size() > 0)
                contractWithAllFields = RevRecHelper.GetContractListWithAllFieldsByItemSetClone(setContractIds);
            
            for(OpportunityLineItem item: itemListWithAllFields) 
                itemListWithAllFieldsMap.put(item.Id, item);
            
            for(Product2 pro : product2WithAllFields) 
                product2WithAllFieldsMap.put(pro.Id, pro);
            
            if(contractWithAllFields.size() > 0) {
                for(Contract contr : contractWithAllFields) 
                    contractWithAllFieldsMap.put(theOppty.Id, contr);
            }
            
            BY_PASS_REVREC_LINE_ITEM_TRIGGER = false;
            
            List<OpportunityLineItem> itemListWithRelations = 
                        [SELECT Id, Name , TotalPrice, Quantity, ServiceDate, PricebookEntry.Name, PricebookEntry.product2.id,
                            PricebookEntry.product2.Name,
                            PricebookEntry.product2.Family,RevRecRule__c, Rule_Assignment__c,
                            RevRecRule__r.Name,
                            RevRecRule__r.Active__c, 
                            RevRecRule__r.Default_Rule__c, 
                            RevRecRule__r.Description__c, 
                            RevRecRule__r.Divide_By__c, 
                            RevRecRule__r.initial_amount__c, 
                            RevRecRule__r.initial_amount_type__c, 
                            RevRecRule__r.Offset_Period__c,  
                            RevRecRule__r.offset_type__c,
                            RevRecRule__r.Period__c, 
                            RevRecRule__r.Period_or_Exact_Days__c, 
                            RevRecRule__r.Recognition_Type__c, 
                            RevRecRule__r.Residual_Amount__c, 
                            RevRecRule__r.Residual_Amount_Type__c, 
                            RevRecRule__r.Revenue_Recognition_End_Date__c,  
                            RevRecRule__r.Revenue_Recognition_Start_Date__c,
                            RevRecRule__r.Milestone_Type__c,
                            RevRecRule__r.Start_Percentage__c,
                            RevRecRule__r.End_Percentage__c,
                            RevRecRule__r.Is_Split_Categories__c,
                            RevRecRule__r.Enable_Manual_Forecast__c,
                            RevRecRule__r.Forecast_With_Zero_Value__c,
                            RevRecOpportunityLineItem__r.Id,
                            RevRecOpportunityLineItem__r.OpportunityLineItemId__c,
                            RevRecOpportunityLineItem__r.TotalRev__c,
                            RevRecOpportunityLineItem__r.DeferredRev__c,
                            RevRecOpportunityLineItem__r.RecognizedRev__c,
                            RevRecOpportunityLineItem__r.CalculatedAt__c,
                            RevRecOpportunityLineItem__r.ResidualAmount__c,
                            RevRecOpportunityLineItem__r.ProductName__c,
                            RevRecOpportunityLineItem__r.Opportunity__c,
                            RevRecOpportunityLineItem__r.Allocated_Amount__c,
                            RevRecOpportunityLineItem__r.RevRecRule__c,
                            RevRecOpportunityLineItem__r.Rule_Assignment__c,
                            RevRecOpportunityLineItem__r.DefReWei__c,
                            RevRecOpportunityLineItem__r.RecRevWei__c,
                            RevRecOpportunityLineItem__r.ResAmtWei__c,
                            PricebookEntry.product2.RevRecRule__r.Id, 
                            PricebookEntry.product2.RevRecRule__r.name, 
                            PricebookEntry.product2.RevRecRule__r.Active__c, 
                            PricebookEntry.product2.RevRecRule__r.Default_Rule__c, 
                            PricebookEntry.product2.RevRecRule__r.Description__c, 
                            PricebookEntry.product2.RevRecRule__r.Divide_By__c, 
                            PricebookEntry.product2.RevRecRule__r.initial_amount__c, 
                            PricebookEntry.product2.RevRecRule__r.initial_amount_type__c, 
                            PricebookEntry.product2.RevRecRule__r.Offset_Period__c,  
                            PricebookEntry.product2.RevRecRule__r.offset_type__c,
                            PricebookEntry.product2.RevRecRule__r.Period__c, 
                            PricebookEntry.product2.RevRecRule__r.Period_or_Exact_Days__c, 
                            PricebookEntry.product2.RevRecRule__r.Recognition_Type__c, 
                            PricebookEntry.product2.RevRecRule__r.Residual_Amount__c, 
                            PricebookEntry.product2.RevRecRule__r.Residual_Amount_Type__c, 
                            PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_End_Date__c,  
                            PricebookEntry.product2.RevRecRule__r.Revenue_Recognition_Start_Date__c,
                            PricebookEntry.product2.RevRecRule__r.Milestone_Type__c,
                            RevRecOpportunityLineItem__r.Converted_Recognized_Amount__c,
                            OpportunityId                           
                        FROM OpportunityLineItem WHERE Id in :LineItemIds];

            Set<Id> RevRecLineItemIds = new Set<id>(); 
            Map<id, OpportunityLineItem> itemListWithRelationsMap = new Map<id, OpportunityLineItem>();
            Map<string, RevRecOpportunityLineItem__c> allNewRevRecLineItemMap = new Map<string, RevRecOpportunityLineItem__c>();
            Map<Id, RevRecOpportunityLineItem__c> mapIdWithallNewRevRecLineItem = new Map<Id,RevRecOpportunityLineItem__c>();
            
            //Code added - 5/24/2017 - As per to atomate date changes 
            Map<Id, OpportunityLineItem> mapLineRevLineIds = new Map<Id, OpportunityLineItem>();
            
            //Code added - 04/07/2015 -  As per recgnized automation
            //Map to hold Line item id with revrecrule id
            Map<Id, Id> mapOppLineItemIdWithRuleId = new Map<Id, Id>();

            for(OpportunityLineItem item : itemListWithRelations) {         
                
                if(item.RevRecOpportunityLineItem__r != null) {
                    RevRecLineItemIds.add(item.RevRecOpportunityLineItem__r.id);
                    mapLineRevLineIds.put(item.RevRecOpportunityLineItem__r.id , item);
                } else {
                    
                    //Code modified - (10/14/2014) - Add Currency of opp to currency of RevRecOpportunityLineItem
                    RevRecOpportunityLineItem__c revRecLineItem = new RevRecOpportunityLineItem__c();
                    revRecLineItem = new RevRecOpportunityLineItem__c(name=item.PricebookEntry.Name, opportunity__c = theOppty.Id, OpportunityLineItemId__c = item.Id, Product_Family__c = item.PricebookEntry.product2.Family);
                    
                     //Code modified - (1/8/2015) - Check if multi currency enabled then do this   
                    if(isMultiCurrencyEnabled)
                        revRecLineItem.put('CurrencyIsoCode', theOppty.get('CurrencyIsoCode'));
                        
                    mapIdWithallNewRevRecLineItem.put(item.Id, revRecLineItem);
                }
                itemListWithRelationsMap.put(item.Id, item);
                
                //code added - 04/07/2015 -  As per recgnized automation
                if(item.RevRecRule__c != null) 
                    mapOppLineItemIdWithRuleId.put(item.Id, item.RevRecRule__c);                  
            }
            
            utilHelper.calRRLIWithCorporateField(mapIdWithallNewRevRecLineItem.values(),theOppty, utl);
            if(mapIdWithallNewRevRecLineItem.values().size() > 0)
                insert(mapIdWithallNewRevRecLineItem.values());
            
            for (Id item : mapIdWithallNewRevRecLineItem.keySet()) {
                allNewRevRecLineItemMap.put(item, mapIdWithallNewRevRecLineItem.get(item));
                mapLineRevLineIds.put( mapIdWithallNewRevRecLineItem.get(item).Id ,  itemListWithRelationsMap.get(item));
            } 
                        
            //Code added - 04/07/2015 - As per recognized automation
            //Map to hold list of milestones with rule
            Map<Id, List<RevRecRuleMilestone__c>> mapRuleIdWithListOfMiles = new Map<Id, List<RevRecRuleMilestone__c>>();
            
            //Code added - 06/13/2015 -  As per Blended Revenue Recognition Requirement
            Map<Id, List<RevRecRuleCategory__c>> mapRuleIdWithListOfCategory = new Map<Id, List<RevRecRuleCategory__c>>();
            
            //Code added - 06/13/2015 - As per Blende Revenue Recognition Requierment
            for(RevRecRuleCategory__c revRecCat : [SELECT Id, Name, Line_Item__c, Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                   Percent__c, Qty__c, Recognition_Type__c, RevRecRule__c, Sequence__c , Is_Split__c, RevRecRuleSplitCategory__c,
                                                   Ultimate_Parent__c,Level__c, Projected_Amount__c, Projected_Percent__c, Projected_Qty__c, Actual_End_Date__c, Actual_Start_Date__c
                                                   FROM RevRecRuleCategory__c WHERE RevRecRule__c IN : mapOppLineItemIdWithRuleId.values() 
                                                   ORDER BY Sequence__c]) {
                //Checking for contains key
                if(mapRuleIdWithListOfCategory.containsKey(revRecCat.RevRecRule__c))
                    mapRuleIdWithListOfCategory.get(revRecCat.RevRecRule__c).add(revRecCat);
                else
                    mapRuleIdWithListOfCategory.put(revRecCat.RevRecRule__c , new List<RevRecRuleCategory__c>{revRecCat} ); 
            }
           
            //Loop through all milestones related to Rule
            for(RevRecRuleMilestone__c miles : [Select Id, Name, Amount__c, Actual_Percent__c, Actual_Amount__c, Actual_Qty__c, Milestone_Date__c, Milestone_Date_Source__c, Projected_Qty__c,
                                                Milestone_Sequence__c, Percent__c, Qty__c, Milestone_Date_Source_Label__c, Projected_Percent__c, Projected_Amount__c, Milestone_Name__c, 
                                                RevRecRule__c From RevRecRuleMilestone__c WHERE RevRecRule__c IN : mapOppLineItemIdWithRuleId.values()
                                                ORDER BY Milestone_Sequence__c]) {
                                                        
                //Checking for containskey
                if(mapRuleIdWithListOfMiles.containsKey(miles.RevRecRule__c))
                    mapRuleIdWithListOfMiles.get(miles.RevRecRule__c).add(miles);
                else
                    mapRuleIdWithListOfMiles.put(miles.RevRecRule__c , new List<RevRecRuleMilestone__c>{miles} );  
            }
            
            Map<Id, RevRecProductRule__c> overrideRuleMap = new  Map<Id, RevRecProductRule__c>();
            
            List<RevRecProductRule__c> orverrideRuleList =
                        [select Id, name, Divide_By__c, initial_amount__c, initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, Start_Percentage__c,End_Percentage__c,
                            Period_or_Exact_Days__c, Recognition_Type__c,  Milestone_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Start_Date__c, End_Date__c, Total_Period__c,
                            RevRecOpportunityLineItem__c, Enable_Manual_Forecast__c, Forecast_With_Zero_Value__c, Is_Manual_Update__c, Is_Default_Overriden__c,Man_Ini_To_Zero__c,
                            Prior_Rule_Type__c,Is_Split_Categories__c, AM_Manual_Cal__c,(SELECT ID, Name, Milestone_Name__c, Milestone_Sequence__c, Projected_Percent__c, Projected_Amount__c, 
                            Percent__c, Amount__c, Qty__c, Milestone_Date_Source__c,Actual_Amount__c,Actual_Qty__c, Actual_Percent__c, Projected_Qty__c, Sales_Manual_Amount__c,
                            Milestone_Date__c, RevRecProductRule__c  From RevRecProductRuleMilestones__r ORDER BY Milestone_Sequence__c),
                            (SELECT Id,  Name, RevRecProductRule__c, RevRecProductRule__r.RevRecOpportunityLineItem__c, Sequence__c, Percent__c, Amount__c, Category_Type__c,Ultimate_Parent__c,Ultimate_Parent__r.Name,
                            Category_End_Date__c , Category_Start_Date__c, Line_Item__c, Qty__c ,Recognition_Type__c,RevRecProductRuleSplitCategory__c,Level__c,
                            RevRecProductRuleSplitCategory__r.Name, Recognized_Amount__c, Deferred_Amount__c , Actual_End_Date__c, Actual_Start_Date__c,Actual_Deferred__c,
                            Projected_Amount__c, Projected_Percent__c, Projected_Qty__c, Sub_Category_support__c
                            From RevRecProductRuleCategorys__r WHERE Is_Split__c = false ORDER BY Sequence__c)
                            from RevRecProductRule__c where RevRecOpportunityLineItem__c in :RevRecLineItemIds];
             
            //Code added - 11/05/2014 - As per Amortized Milestone Rule Requirements
            //Loop thruggh the override rule                
            for(RevRecProductRule__c item : orverrideRuleList) {

                //Check if ovveride rule exist
                if(!item.Name.contains('[overridden] '))
                    overrideRuleMap.put(item.RevRecOpportunityLineItem__c, item);
                else {
                    if(overrideRuleMap.size() >0 && overrideRuleMap != null)
                        overrideRuleMap.put(item.RevRecOpportunityLineItem__c, item);
                    else
                        overrideRuleMap.put(item.RevRecOpportunityLineItem__c, item);
                }
            }
            //Remove the existing schedule records for the theOppId
            utilHelper.scheduleCleanup(LineItemIds);
            
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oliListTemp = new List<OpportunityLineItem>();
            List<RevRecOpportunityLineItem__c> revRecOliList = new List<RevRecOpportunityLineItem__c>();
            List<RevRecProductRule__c> overrideRuleList = new List<RevRecProductRule__c>();
            
            // Code added - 11/05/2014 - As per Amortized Milestone Rule Requirements 
            // Mapp to hold  revrecMilestone with name
            Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();
            Map<id, List<RevRecProductRuleMilestone__c>> revRecProductRuleMilestonesMap = new Map<id, List<RevRecProductRuleMilestone__c>>();
            List<RevRecOpportunityLineItemSchedule__c> allSchedules = new List<RevRecOpportunityLineItemSchedule__c>();
            
            //Code added - 06/18/2015 -  As per Blended Revenue Recognition 
            
            Map<Id, List<RevRecProductRuleCategory__c>> mapLineItemWithProductCategory = new  Map<Id, List<RevRecProductRuleCategory__c>>();
            List<RevRecProductRuleCategory__c> overrideRuleCategories;
                        
            for(OpportunityLineItem item : itemListWithRelations) {
                
                String oppLineItemId = item.Id;
                OpportunityLineItem oli = itemListWithAllFieldsMap.get(oppLineItemId);
                Product2 pro = product2WithAllFieldsMap.get(item.PricebookEntry.Product2.Id);
                Contract contr = new Contract();
                
                if(contractWithAllFieldsMap != null && contractWithAllFieldsMap.size() > 0) 
                    contr = contractWithAllFieldsMap.get(item.OpportunityId);   
                
                OpportunityLineItem oli1 = itemListWithRelationsMap.get(oppLineItemId);
                RevRecOpportunityLineItem__c revRecLineItem = oli1.RevRecOpportunityLineItem__r;
                
                //Added to assign total amount value for opplineitem for blended rule
                revreclineItem.TotalRev__c = oli1.TotalPrice;
                if (revRecLineItem == null)
                        revRecLineItem = allNewRevRecLineItemMap.get(oppLineItemId);
                
                if(oli.RevRecOpportunityLineItem__c == null) {
                    oli.RevRecOpportunityLineItem__c = revRecLineItem.id;
                    if(!Test.isRunningTest()) 
                        oliListTemp.add(oli);
                }
                
                if(Test.isRunningTest()) 
                    oliListTemp.add(oli);
                                
                oli1.RevRecOpportunityLineItem__c = revRecLineItem.id; 
                revRecLineItem.ProductName__c = oli1.PricebookEntry.Name;
                revRecLineItem.OpportunityLineItemId__c = oli1.Id;
                revReclineItem.Allocated__c  = 0.00;
            
                //Code modified - (1/08/2015) - Add Currency of Opportunity as Schedule currency
                if(isMultiCurrencyEnabled)
                    revRecLineItem.put('CurrencyIsoCode' , oli1.get('CurrencyIsoCode'));
                if (revRecLineItem.Opportunity__c == null)
                    revRecLineItem.Opportunity__c = theOppId;
                RevRecProductRule__c overrideRule = overrideRuleMap.get(revRecLineItem.Id);
                List<RevRecProductRuleMilestone__c> overrideRuleMileStone = new List<RevRecProductRuleMilestone__c>();
                //Code added-06/13/2015-As per Blended Revenue Recognition requirement
                overrideRuleCategories = new  List<RevRecProductRuleCategory__c>();

                //Checking for Override Rule
                if (overrideRule == null){
                    //Initilize lists 
                    overrideRuleMileStone = new List<RevRecProductRuleMilestone__c>();
                    overrideRule = new RevRecProductRule__c();
                    overrideRuleCategories = new  List<RevRecProductRuleCategory__c>();
                   // Code added - 11/05/2014 - As per Amortized Milestone Rule Requirements 
                   //Add mapRevRecMileStoneWithName as argummnet in method
                   msg = CalculateOverrideRuleFromRevRecRule(theOppty, oli, pro, oli1.RevRecRule__r, overrideRule, (mapRuleIdWithListOfMiles != null ) ? mapRuleIdWithListOfMiles.get(oli1.RevRecRule__c) : null, 
                                                            overrideRuleMileStone, (mapRevRecMileStoneWithName !=null) ? mapRevRecMileStoneWithName: null, mapRuleIdWithListOfCategory != null ? mapRuleIdWithListOfCategory.get(oli1.RevRecRule__c) : null, 
                                                            overrideRuleCategories, utl, contr);
                   
                } else {
                    //Code added - 05/15/2015 - As per 1.38 Release Issue Fixing
                    OverrideRule.Revenue_Recognition_End_Date__c = oli1.RevRecRule__r.Revenue_Recognition_End_Date__c;
                    OverrideRule.Revenue_Recognition_Start_Date__c = oli1.RevRecRule__r.Revenue_Recognition_Start_Date__c;

                    if(overrideRule.RevRecProductRuleCategorys__r.size() > 0)
                        overrideRuleCategories =  overrideRule.RevRecProductRuleCategorys__r;
                    
                    //Temp list of milestones
                    List<RevRecProductRuleMilestone__c> listMilesTemp = new  List<RevRecProductRuleMilestone__c>(); 

                    //Checking for Milestons list size
                    if(overrideRule.RevRecProductRuleMilestones__r.size() > 0) {
                       
                        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)
                            mapRuleWithExistingMileStone.put(overrideRule.Id, overrideRule.RevRecProductRuleMilestones__r);
                        
                        //Populate list
                        overrideRuleMileStone = overrideRule.RevRecProductRuleMilestones__r;

                        //Checking for Rule Recognition type 
                        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                                            
                            //Checking for list size
                            if(overrideRuleMileStone.size() > 0) {

                                //Set milestone date to null
                                Date mileStoneDate = null;
                                
                                //Loop through Milestones
                                for(RevRecProductRuleMilestone__c  itm : overrideRuleMileStone) {
                                    
                                    //get the start date and end date     
                                    String RevRecMileStoneDateSourceField = itm.Milestone_Date_Source__c;
                                        
                                    //Checking if Date source is produuct / Opportunity /  Manual 
                                    if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY)){
                                        if(RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                                            string fieldName = RevRecMileStoneDateSourceField.subString(20, RevRecMileStoneDateSourceField.length()); 
                                            mileStoneDate = (Date)oli.get(fieldName);
                                        }
                                        else {
                                            string fieldName = RevRecMileStoneDateSourceField.subString(12, RevRecMileStoneDateSourceField.length()); 
                                            mileStoneDate = (Date)theOppty.get(fieldName);
                                        } 
                                    } else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                                        string fieldName = RevRecMileStoneDateSourceField.subString(8, RevRecMileStoneDateSourceField.length());
                                        mileStoneDate = (Date)pro.get(fieldName);
                                    }else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                                        string fieldName = RevRecMileStoneDateSourceField.subString(9, RevRecMileStoneDateSourceField.length());
                                        if(contr != null)
                                            mileStoneDate = (Date)contr.get(fieldName);
                                         else {
                                             msg = Constants.START_END_DATE_CANNOT_NUll_ERROR_MESSAGE;
                                         }
                                    } else
                                        mileStoneDate = itm.MileStone_Date__c;
                                    
                                    //Checking if Date source is produuct / Opportunity / Manual  
                                   if ((RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) 
                                        || RevRecMileStoneDateSourceField != null 
                                        && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY_COLON)) {
                                   
                                        //Getting field label from field Api name
                                        if(allDates.containsKey(RevRecMileStoneDateSourceField))
                                             milestoneDateSource = allDates.get(RevRecMileStoneDateSourceField);
                                   } else
                                        milestoneDateSource = constants.MILESTONE_DATE_MANUAL;
                                    
                                    //Set milestone date label
                                    itm.Milestone_Date_Source_Label__c = milestoneDateSource;
                                    itm.Milestone_Date__c = mileStoneDate;
                                    
                                    listMilesTemp.add(itm);
                                }
                            }
                        } 
                    }
                    if(listMilesTemp.size() > 0)
                        //Assign temp list to Override milestone list
                        overrideRuleMileStone = listMilesTemp;
                }
                
                oliList.add(oli);
                revRecOliList.add(revRecLineItem);
                overrideRuleList.add(overrideRule);
                revRecProductRuleMilestonesMap.put(oli.Id, overrideRuleMileStone);
                mapRROLIIdWithMiles.put(revRecLineItem.Id, overrideRuleMileStone);
                mapLineItemIdWithRevRecLineItem.put(oli.Id , revRecLineItem);

                //List milestone t0 bbe deleted
                List<RevRecProductRuleMilestone__c> milestoneToBeDeleted = new List<RevRecProductRuleMilestone__c>();
                
                //Loop over overrideRuleList
                for(RevRecProductRule__c prdRule : overrideRuleList) {
                    
                    //Checking for Recognition type
                    if(prdRule.Id != null && prdRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE  ) {
                        
                        if(mapRuleWithExistingMileStone.size() > 0) {
                        
                            OpportunityLineItem lineItem = new OpportunityLineItem();
                            if(mapLineRevLineIds.containsKey( prdRule.RevRecOpportunityLineItem__c)) 
                                lineItem = mapLineRevLineIds.get(prdRule.RevRecOpportunityLineItem__c);
                            
                            Product2 prd = new Product2(); 
                            Contract cntr = new Contract();
                            
                            if(product2WithAllFieldsMap.containsKey(lineItem.PriceBookEntry.Product2.Id))
                                prd = product2WithAllFieldsMap.get(lineItem.PriceBookEntry.Product2.Id);
                                
                            if(contractWithAllFieldsMap.containsKey(lineItem.OpportunityId))
                                cntr = contractWithAllFieldsMap.get(lineItem.OpportunityId);
                                
                            if(mapRuleWithExistingMileStone.containsKey(prdRule.Id)) {
                                
                                //Get the start date and end date
                                String RevRecStartDateField = lineItem.RevRecRule__r.Revenue_Recognition_Start_Date__c;
                                String RevRecEndDateField = lineItem.RevRecRule__r.Revenue_Recognition_End_Date__c;
                                Date startDateTemp = prdRule.Start_Date__c;
                                Date endDateTemp = prdRule.End_Date__c;
                                
                                AmortizeMileStartEndDate wrp = utilHelper.startEndDateForAMRule(prdRule.Start_Date__c ,prdRule.End_Date__c,theOppty,lineItem,prd, RevRecEndDateField,RevRecStartDateField, cntr);
                                
                                //Assigning valus
                                if(prdRule.Is_Opportuunity_Date_Change__c)
                                    prdRule.Start_Date__c = wrp.startDate;
                                if(prdRule.Is_Opportuunity_End_Date_Change__c)
                                    prdRule.End_Date__c = wrp.endDate;
                                
                                if(startDateTemp != prdRule.Start_Date__c || endDateTemp != prdRule.End_Date__c ) {
                                    mapRuleWithExistingMileStone.get(prdRule.Id).clear();
                                    milestoneToBeDeleted.addAll(mapRuleWithExistingMileStone.get(prdRule.Id));
                                    ruleToUpdate.add(prdRule);
                                }
                            }
                        }
                    }
                }
                
                //Populate map - Code added - 06/18/2015 -- As per Blended Revenue Recognition
                mapLineItemWithProductCategory.put(oli.Id, overrideRuleCategories);
                //Code added - 06/18/2015 - As per Blended revenue recognition requirement
                if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE || 
                    overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE)
                    constants.IS_BY_PASS_TRIGGER = true;
            }
            
            //Overridden rule insertion in case of Amortized milestone or milestone rule
            if(overriddenRuleToBeInserted.size() > 0) {
                
                insert overriddenRuleToBeInserted;
                    
                List<RevRecProductRuleMilestone__c> milesToBeInserted = new List<RevRecProductRuleMilestone__c>();
               
                for(RevRecProductRule__c overriddenRule : overriddenRuleToBeInserted) {
                    
                    if(mapRROLIIdWithMiles.containsKey(overriddenRule.RevRecOpportunityLineItem__c) && overriddenRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                        
                        for(RevRecProductRuleMilestone__c milestone : mapRROLIIdWithMiles.get(overriddenRule.RevRecOpportunityLineItem__c)) {
                            
                            milestone.RevRecProductRule__c = overriddenRule.Id;  
                            milesToBeInserted.add(milestone);
                        }
                    }
                }

                utilHelper.calMileWithCorporateField(milesToBeInserted, theOppty, utl);
                if(milesToBeInserted.size() > 0) 
                    insert milesToBeInserted;                 
            } 
                
            try {

                /** IF BLENDED RULE IS ALREADY WHILE ADDING ON OPPORTUNITY **/
                //Added on 04/13/2016 - As per blended rule split template
                Set<Id> setCatIds = new Set<Id>();
                
                //Checking for the map size and then insert override rule
                if(mapOldRuleIdWithNewOverrideRule.size() > 0) {
                    
                    //By pass trigger
                    Constants.IS_BY_PASS_RULE_TRIGGER = true;
                    
                    //Loop over Override Key set which is ruleId-lineItem ID
                    for(String key : mapOldRuleIdWithNewOverrideRule.keySet()) {    
                        
                        //Getting line item id
                        String lineItemId = key.substringAfter('-');
                        mapOldRuleIdWithNewOverrideRule.get(key).RevRecOpportunityLineItem__c = mapLineItemIdWithRevRecLineItem.get(lineItemId).Id;
                    }
                    
                    //Insert overriden rule
                    insert mapOldRuleIdWithNewOverrideRule.values();
                    //Reset flag
                    Constants.IS_BY_PASS_RULE_TRIGGER = false;
                }

                //Checking for the  map size and insert map values
                if(mapOldRuleCategoryIdWithNewCatg.size() > 0) {

                    //Loop over mapOldRuleCategoryIdWithNewCatg and insert all categories
                    for(RevRecProductRuleCategory__c prdCat : mapOldRuleCategoryIdWithNewCatg.values()) {
                        
                        //Check if multi currency enabled in org or not
                        if(isMultiCurrencyEnabled) {
                            Decimal pro = theOppty.Probability / 100;
                            if(prdCat.Actual_Deferred__c != null) {
                                prdCat.Converted_Actual_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Actual_Deferred__c)).replace('<br/>', '');
                                prdCat.Cor_Act_Def__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), prdCat.Actual_Deferred__c));
                            } else {
                                prdCat.Converted_Actual_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                prdCat.Cor_Act_Def__c = 0.00;
                            }
                            if(prdCat.Deferred_Amount__c != null) {
                                prdCat.Converted_Actual_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Deferred_Amount__c)).replace('<br/>', '');
                                prdCat.Cor_Def_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), prdCat.Deferred_Amount__c));
                           } else {
                                prdCat.Converted_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                prdCat.Cor_Def_Amt__c = 0.00;
                            }  
                            if(prdCat.Recognized_Amount__c != null) {
                                prdCat.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Recognized_Amount__c)).replace('<br/>', '');
                                prdCat.Cor_Rec_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), prdCat.Recognized_Amount__c));
                           } else {
                                prdCat.Converted_Recognized_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                prdCat.Cor_Rec_Amt__c = 0.00;
                            }
                        }
                        prdCat.RevRecProductRule__c = mapOldRuleIdWithNewOverrideRule.get(prdCat.Old_Rule_Id__c).Id;
                    }
                        
                    utilHelper.calProCatWithCorporateField(mapOldRuleCategoryIdWithNewCatg.values(), theOppty, utl);
                    insert mapOldRuleCategoryIdWithNewCatg.values();
                    
                    //Loop over all inserted categories and then relate all parent and splitted category
                    for(RevRecProductRuleCategory__c prdCat : mapOldRuleCategoryIdWithNewCatg.values()) {
                        
                        //Checking old splitt category id
                        if(prdCat.Old_Splitted_Category__c != null) {
                            String key = prdCat.Old_Splitted_Category__c + '_' + prdCat.Line_Item_Id__c;
                            prdCat.RevRecProductRuleSplitCategory__c = mapOldRuleCategoryIdWithNewCatg.get(key).Id;                         
                        }
                        
                        //Checking old ultimate parent id
                        if(prdCat.Old_Ultimate_Category__c != null) {
                            string key = prdCat.Old_Ultimate_Category__c + '_' + prdCat.Line_Item_Id__c;
                            prdCat.Old_Ultimate_Category__c = mapOldRuleCategoryIdWithNewCatg.get(key).Id;
                        }
                            
                        //If old categopry is splitted then split the new one
                        if(prdCat.Old_Split__c)
                            prdCat.Is_Split__c = true;
                    }
                    //Upsert the values
                    upsert mapOldRuleCategoryIdWithNewCatg.values();
                   
                    mapLineItemWithProductCategory  = new Map<Id, List<RevRecProductRuleCategory__c>>();
                    
                    //Query over all the Categories
                    //mapParentIdWithListOfSplits
                    for(RevRecProductRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                    Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Line_Item_Id__c,
                                                                    Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Ultimate_Parent__c,
                                                                    RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,Sub_Category_support__c,Level__c,
                                                                    (Select Id,Is_Split__c , Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                     Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Ultimate_Parent__c,Level__c,
                                                                     Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Line_Item_Id__c,
                                                                     RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,Sub_Category_support__c From RevRecProductRuleSplitCategorys__r 
                                                                     ORDER BY Sequence__c) FROM RevRecProductRuleCategory__c
                                                                    Where RevRecProductRule__c IN: mapOldRuleIdWithNewOverrideRule.values() 
                                                                    AND ID IN: mapOldRuleCategoryIdWithNewCatg.values() ORDER BY Level__c ASC]) {
                                                                                  
                        //Checking for size of child - Populate map with values
                        mapIdWithAllCatg.put(revCategory.Id, revCategory);
                        if(revCategory.RevRecProductRuleSplitCategorys__r.Size() > 0)
                            mapParentIdWithListOfSplits.put(revCategory.Level__c + '-'+ revCategory.Id, revCategory.RevRecProductRuleSplitCategorys__r);
                    }
                    //Variables for roll up the data on parent
                    Decimal totalRecognozedForParent ;
                    Decimal totalDeferredForParent ;
                    Decimal totalActulDeferredForParent;
                    
                    //Loop over all categories 
                    for(String proCatParentId : mapParentIdWithListOfSplits.keySet()) {
                         
                         String fullStr = proCatParentId;
                         proCatParentId = proCatParentId.substringAfter('-'); 
                         totalRecognozedForParent =0.00 ; totalDeferredForParent = 0.00; totalActulDeferredForParent = 0.00;
                             
                        //Variables to hold recognized and deferred amount
                        Decimal orignalLineItemAmount = mapIdWithAllCatg.get(proCatParentId).Recognized_Amount__c 
                                                         + mapIdWithAllCatg.get(proCatParentId).Actual_Deferred__c; 
                        Decimal orignalLineItemQty  = ((orignalLineItemAmount) / itemListWithRelationsMap.get(mapIdWithAllCatg.get(proCatParentId).Line_Item_Id__c).TotalPrice);
                        Decimal recognizedAmount ;
                        Decimal deferredAmount;
                        Decimal actualDeferred;
                        Decimal amountToSplit = orignalLineItemAmount; 
                        Decimal qtyToSplit = orignalLineItemQty;
                        Decimal outstandingBalance = orignalLineItemAmount;
                        Decimal totalSplitRecognized = 0.00;
                        Decimal totalSplitDeferred = 0.00; 
                        Decimal actualCatDifference = 0.00;
                        Decimal prob = theOppty.Probability/100;
                        for(RevRecProductRuleCategory__c childCat : mapParentIdWithListOfSplits.get(fullStr)) {
                            
                            //Reset values 
                            recognizedAmount = 0.00; 
                            deferredAmount = 0.00;
                            actualDeferred = 0.00;
                                             
                             //Initilize product category wrapper
                             listSplitCategoryWrap = new List<RevRecProductRuleController.ProductRuleCategoryWrapper>();
                             
                             //Loop over categories to popualate wrapper
                             for(RevRecProductRuleCategory__c cCat : mapParentIdWithListOfSplits.get(fullStr)) 
                                listSplitCategoryWrap.add(new RevRecProductRuleController.ProductRuleCategoryWrapper(cCat ,Integer.valueof(cCat.Sequence__c), new List<SelectOption>() ,false ));
                                                       
                            //Calling method to calculate recognized and deferred amount
                            wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlendedSplit(childCat, outstandingBalance, recognizedAmount, deferredAmount, itemListWithRelationsMap.get(childCat.Line_Item_Id__c), msg, null, listSplitCategoryWrap, actualDeferred, amountToSplit, qtyToSplit, childCat.RevRecProductRule__r);
                                                        
                            recognizedAmount = wrapCalculation.recognizedAmount; 
                            deferredAmount = wrapCalculation.deferredAmount;
                            actualDeferred = wrapCalculation.actualDeferred;
                            outstandingBalance = wrapCalculation.outStandingBalance;
                            actualCatDifference  = wrapCalculation.actualCatDifference;
                            msg = wrapCalculation.msg;   
                            //Set values in Product Category
                            childCat.Recognized_Amount__c = recognizedAmount;  
                            childCat.Rec_Amt_Wei__c = recognizedAmount * prob;   
                            childCat.Deferred_Amount__c = deferredAmount;
                            childCat.Deferred_Amount_Weighted__c = deferredAmount * prob;
                            childCat.Actual_Deferred__c = actualDeferred;
                            childCat.Act_Def_Wei__c = actualDeferred * prob;
                            outstandingBalance = outstandingBalance - actualCatDifference;
                            
                            //Holding sum of all child and then roll up it on parent
                            totalDeferredForParent += deferredAmount;
                            totalRecognozedForParent += recognizedAmount; 
                            totalActulDeferredForParent += actualDeferred;
                            
                            //categoriesToUpdate.add(childCat);
                            mapIdWithAllCatg.get(childCat.Id).Recognized_Amount__c = recognizedAmount;
                            mapIdWithAllCatg.get(childCat.Id).Rec_Amt_Wei__c = recognizedAmount * prob;
                            mapIdWithAllCatg.get(childCat.Id).Deferred_Amount__c = deferredAmount;
                            mapIdWithAllCatg.get(childCat.Id).Deferred_Amount_Weighted__c = deferredAmount * prob;
                            mapIdWithAllCatg.get(childCat.Id).Actual_Deferred__c = actualDeferred;
                            mapIdWithAllCatg.get(childCat.Id).Act_Def_Wei__c = actualDeferred * prob;
                            
                            //Checking for the non splitted categoruies only
                            if(!setCatIds.contains(childCat.Id) && !childCat.Is_Split__c) {
                                
                                if(!mapLineItemWithProductCategory.containsKey(childCat.Line_Item_Id__c))
                                    mapLineItemWithProductCategory.put(childCat.Line_Item_Id__c , new List<RevRecProductRuleCategory__c>{childCat});
                                else
                                    mapLineItemWithProductCategory.get(childCat.Line_Item_Id__c).add(childCat);
                               //Add id into set
                               setCatIds.add(childCat.Id);
                            }
                        }
                            
                        //Populate map value
                        mapIdWithAllCatg.get(proCatParentId).Recognized_Amount__c = totalRecognozedForParent;
                        mapIdWithAllCatg.get(proCatParentId).Deferred_Amount__c = totalDeferredForParent;
                        mapIdWithAllCatg.get(proCatParentId).Actual_Deferred__c = totalActulDeferredForParent;
                        mapIdWithAllCatg.get(proCatParentId).Rec_Amt_Wei__c = recognizedAmount * prob;
                        mapIdWithAllCatg.get(proCatParentId).Deferred_Amount_Weighted__c = deferredAmount * prob;
                        mapIdWithAllCatg.get(proCatParentId).Act_Def_Wei__c = actualDeferred * prob;
                        
                        //Populatin map with categories
                        if(!setCatIds.contains(proCatParentId) && !mapIdWithAllCatg.get(proCatParentId).Is_Split__c) {
                            if(!mapLineItemWithProductCategory.containsKey(mapIdWithAllCatg.get(proCatParentId).Line_Item_Id__c))
                                mapLineItemWithProductCategory.put(mapIdWithAllCatg.get(proCatParentId).Line_Item_Id__c , new List<RevRecProductRuleCategory__c>{mapIdWithAllCatg.get(proCatParentId)});
                            else
                                mapLineItemWithProductCategory.get(mapIdWithAllCatg.get(proCatParentId).Line_Item_Id__c).add(mapIdWithAllCatg.get(proCatParentId));
                            //Add values into set
                            setCatIds.add(proCatParentId);
                        }
                    }
                    
                    //Loop OVER ALL CATEGORY  and populate noo splitted categories into map
                    for(Id catId : mapIdWithAllCatg.keySet()) {
                        
                        if(!setCatIds.contains(catId) &&  !mapIdWithAllCatg.get(catId).Is_Split__c) {
                             if(!mapLineItemWithProductCategory.containsKey(mapIdWithAllCatg.get(catId).Line_Item_Id__c))
                                mapLineItemWithProductCategory.put(mapIdWithAllCatg.get(catId).Line_Item_Id__c , new List<RevRecProductRuleCategory__c>{mapIdWithAllCatg.get(catId)});
                            else
                                mapLineItemWithProductCategory.get(mapIdWithAllCatg.get(catId).Line_Item_Id__c).add(mapIdWithAllCatg.get(catId));
                        }
                    }
                    
                    //Checkiing for the 
                    if(mapIdWithAllCatg.size() > 0 ) {
                        
                        for(RevRecProductRuleCategory__c pCat : mapIdWithAllCatg.values()) {
                            
                            //Code modified - (07/10/2017) - Check if multi currency enabled in org or not
                            if(isMultiCurrencyEnabled) {
                                
                                 //Checking for null
                                if(pCat.Recognized_Amount__c != null) {
                                    pCat.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), pCat.Recognized_Amount__c)).replace('<br/>', '');
                                    pCat.Cor_Rec_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), pCat.Recognized_Amount__c));
                                } else {
                                    pCat.Converted_Recognized_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                    pCat.Cor_Rec_Amt__c = 0.00;
                                }
                                 //Checking for null
                                if(pCat.Deferred_Amount__c != null) {
                                    pCat.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), pCat.Deferred_Amount__c)).replace('<br/>', '');
                                    pCat.Cor_Def_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), pCat.Deferred_Amount__c));
                                } else {
                                    pCat.Converted_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )'; 
                                    pCat.Cor_Def_Amt__c = 0.00;
                                }   
                                //Checking for null
                                if(pCat.Actual_Deferred__c != null) {
                                    pCat.Converted_Actual_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), pCat.Actual_Deferred__c)).replace('<br/>', '');
                                    pCat.Cor_Act_Def__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), pCat.Actual_Deferred__c));
                                } else {
                                    pCat.Converted_Actual_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                    pCat.Cor_Act_Def__c = 0.00;
                                }
                            }
                        }
                        
                        utilHelper.calProCatWithCorporateField(mapIdWithAllCatg.values(), theOppty, utl);
                        update mapIdWithAllCatg.values();
                    }
                }
                String msg1 = msg;
                string debugInfo = 'oliList:' + oliList.size() + '   revRecOliList:' + revRecOliList.size() +  + '   allSchedules:' + allSchedules.size() +  + '   overrideRuleList:' + overrideRuleList.size() +  + '   revRecProductRuleMilestonesMap:' + revRecProductRuleMilestonesMap.values();
                msg = EvaluateRevRecSchedule(theOppty, oliList, revRecOliList, allSchedules,theStage,overrideRuleList, revRecProductRuleMilestonesMap, mapLineItemWithProductCategory);
                debugInfo += '     oliList:' + oliList.size() + '   revRecOliList:' + revRecOliList.size() +  + '   allSchedules:' + allSchedules.size() +  + '   overrideRuleList:' + overrideRuleList.size() +  + '   revRecProductRuleMilestonesMap:' + revRecProductRuleMilestonesMap.values();

               if(String.isNotBlank(msg1))
                    msg = msg1;
                
                //Code added - 10/21/2014
                BY_PASS_OPP_LINE_ITEM_TRIGGER = true;
                
                //Code is added for weighted calculation
                if(theOppty.Probability != null && revRecOliList.size() > 0) {
                    Decimal pro = theOppty.Probability / 100;
                    for(RevRecOpportunityLineItem__c item : revRecOliList) {
                        if(item.RecognizedRev__c != null)
                            item.RecRevWei__c = item.RecognizedRev__c * pro;
                        if(item.DeferredRev__c != null)
                            item.DefReWei__c = item.DeferredRev__c * pro;
                        if(item.ResidualAmount__c != null)
                            item.ResAmtWei__c = item.ResidualAmount__c * pro;
                        if(item.TotalRev__c != null)
                            item.Total_Amt_Wei__c = item.TotalRev__c * pro;
                    }
                }
                utilHelper.calRRLIWithCorporateField(revRecOliList, theOppty, utl);
                update(revRecOliList);
                
                //Re-initialization
                theOppty.REVvue_TotalRecognized__c = 0.00; theOppty.REVvue_TotalDeferred__c = 0.00; theOppty.REVvue_TotalResidual__c = 0.00;
                theOppty.REVvue_TotalOpportunity__c = 0.00; theOppty.REVvue_Total_Opp_wei__c = 0.00;
                theOppty.REVvue_TotalRecognizedwei__c = 0.00; theOppty.REVvue_TotalDeferredwei__c = 0.00;
                theOppty.REVvue_TotalResidualwei__c = 0.00; theOppty.REVvue_TotalForecastedwei__c = 0.00;
                theOppty.REVvue_TotalForecasted__c = 0.00;
                
                for(RevRecOpportunityLineItem__c item : revRecOliList) {
                   theOppty.REVvue_TotalOpportunity__c += item.TotalRev__c != null ?  item.TotalRev__c : 0.00;
                   theOppty.REVvue_TotalRecognized__c += item.RecognizedRev__c != null ? item.RecognizedRev__c : 0.00;
                   theOppty.REVvue_TotalDeferred__c += item.DeferredRev__c !=  null ? item.DeferredRev__c : 0.00;
                   theOppty.REVvue_TotalResidual__c += item.ResidualAmount__c != null ? item.ResidualAmount__c : 0.00;
                   theOppty.REVvue_TotalForecasted__c += item.ForecastedRev__c != null ?  item.ForecastedRev__c : 0.00;
                   //Code added on 11/16/2016 for weighted calculation on opp level
                   theOppty.REVvue_Total_Opp_wei__c += ((item.TotalRev__c != null ?  item.TotalRev__c : 0.00) * theOppty.Probability) / 100;
                   theOppty.REVvue_TotalRecognizedwei__c += (item.RecRevWei__c != null ? item.RecRevWei__c : 0.00) ;
                   theOppty.REVvue_TotalDeferredwei__c += (item.DefReWei__c !=  null ? item.DefReWei__c : 0.00);
                   theOppty.REVvue_TotalResidualwei__c += (item.ResAmtWei__c != null ? item.ResAmtWei__c : 0.00) ;
                   theOppty.REVvue_TotalForecastedwei__c += (item.ForeRevWei__c != null ? item.ForeRevWei__c : 0.00);
                }
                Opportunity opp = [SELECT Id, REVvue_Total_Opp_wei__c, REVvue_TotalDeferredwei__c, REVvue_TotalRecognizedwei__c, REVvue_TotalResidualwei__c, REVvue_TotalOpportunity__c, REVvue_TotalRecognized__c, REVvue_TotalDeferred__c, REVvue_TotalResidual__c, Probability, REVvue_TotalForecasted__c, REVvue_TotalForecastedwei__c
                                   FROM Opportunity WHERE Id =: theOppty.Id];
                
                //Check to avoid opp update with lightning experience
                if(theOppty != null && (opp.REVvue_TotalOpportunity__c != theOppty.REVvue_TotalOpportunity__c || opp.REVvue_TotalRecognized__c != theOppty.REVvue_TotalRecognized__c ||
                                        opp.REVvue_TotalDeferred__c != theOppty.REVvue_TotalDeferred__c || opp.REVvue_TotalResidual__c != theOppty.REVvue_TotalResidual__c ||
                                        opp.REVvue_TotalForecasted__c != theOppty.REVvue_TotalForecasted__c || opp.REVvue_TotalForecastedwei__c != theOppty.REVvue_TotalForecastedwei__c ||
                                        opp.REVvue_Total_Opp_wei__c != theOppty.REVvue_Total_Opp_wei__c || opp.REVvue_TotalDeferredwei__c != theOppty.REVvue_TotalDeferredwei__c ||
                                        opp.REVvue_TotalRecognizedwei__c != theOppty.REVvue_TotalRecognizedwei__c || opp.REVvue_TotalResidualwei__c != theOppty.REVvue_TotalResidualwei__c)) {
                    update theOppty;                          
                }
                
                if(oliListTemp.size() > 0)
                    update(oliListTemp);
   
                BY_PASS_OPP_LINE_ITEM_TRIGGER = false;
                                
                //Code updated - 04/12/2017 - As per to resolve duplicate opp amount issue
                //insert allSchedules;
                if(allSchedules.size() > 0) { 

                    //Query updated with adding filter checking for not null or blank
                    utilHelper.scheduleCleanup(LineItemIds);
                
                    //Set to hold uniwque string
                    Set<String> setUniqueSchs = new Set<String>();
                    
                    //Temp list of schedule
                    List<RevRecOpportunityLineItemSchedule__c> allTempSchedule = new List<RevRecOpportunityLineItemSchedule__c>();
                    
                    //Loop over schedules
                    for(RevRecOpportunityLineItemSchedule__c sch : allSchedules) {

                        //Check if multi currency enabled in org or not
                        if(isMultiCurrencyEnabled) {
                            Decimal pro = theOppty.Probability/100;
                            //Checking for null
                            if(sch.DeferredRev__c != null) {
                                sch.Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), sch.DeferredRev__c)).replace('<br/>', '');
                                sch.Cor_Def_Rev__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), sch.DeferredRev__c));
                            } else {
                                sch.Converted_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                sch.Cor_Def_Rev__c = 0.00;
                            }
                            //Checking for null
                            if(sch.RecognizedRev__c != null) {
                                sch.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), sch.RecognizedRev__c)).replace('<br/>', '');
                                sch.Cor_Rec_Rev__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), sch.RecognizedRev__c));
                            } else {
                                sch.Converted_Recognized_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                sch.Cor_Rec_Rev__c = 0.00;
                            }
                            //Checking for null
                            if(sch.LineItemAmountTotal__c != null) {
                                sch.Converted_LineItem_AmountTotal_c__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), sch.LineItemAmountTotal__c)).replace('<br/>', '');
                                sch.Cor_LI_Amt_Total__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), sch.LineItemAmountTotal__c));
                            } else {
                                sch.Converted_LineItem_AmountTotal_c__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                sch.Cor_LI_Amt_Total__c = 0.00;
                            }
                            //Checking for null
                            if(sch.RecognizedRevTotal__c != null) {
                                sch.Converted_Recognized_Total_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), sch.RecognizedRevTotal__c)).replace('<br/>', '');
                                sch.Cor_Rec_Total__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), sch.RecognizedRevTotal__c));
                            } else {
                                sch.Converted_Recognized_Total_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                sch.Cor_Rec_Total__c = 0.00;
                            }
                            //Checking for null
                            if(sch.ResidualAmountTotal__c != null) {
                                sch.Converted_Residual_Total_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), sch.ResidualAmountTotal__c)).replace('<br/>', '');
                                sch.Cor_Res_Total_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), sch.ResidualAmountTotal__c));
                            } else {
                                sch.Converted_Residual_Total_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                sch.Cor_Res_Total_Amt__c = 0.00;
                            }
                        }
                        
                        if(sch.Date__c != null) {
                                                    
                            //String of Month and Year with ReverecLine Item Id
                            String uniqueString = String.valueOf(sch.Sequence__c) + sch.RevRecOpportunityLineItem__c +  ' - '+ String.ValueOf(sch.Date__c.month()) + ' - ' + String.valueOf(sch.Date__c.year() ) ;
                            
                            //Checkeing for Unique
                            if(!setUniqueSchs.contains(uniqueString))
                                allTempSchedule.add(sch);
                             
                            //Add into set
                            setUniqueSchs.add(uniqueString);
                        }
                    }
                    //Clear main list and assign temp list in it
                    allSchedules.clear();
                    allSchedules = allTempSchedule;

                    utilHelper.calOLISchWithCorporateField(allSchedules,theOppty,utl);
                      
                    //flag to bypass trigger
                    constants.IS_BY_PASS_SCHEDULES_TRIGGER = true;
                    
                    //Insert RevRecSchedules
                    insert allSchedules; 
                    
                    constants.IS_BY_PASS_SCHEDULES_TRIGGER = false;
                }
                               
                //List Milestone to be Upsert
                List<RevRecProductRuleMilestone__c> mileToInsert = new List<RevRecProductRuleMilestone__c>();
                for(Id oliId : revRecProductRuleMilestonesMap.keySet()) 
                    mileToInsert.addAll(revRecProductRuleMilestonesMap.get(oliId));

                //list of schedule category to be inserted
                List<RevRecScheduleCategory__c> listSchCategoryToBeInserted = new List<RevRecScheduleCategory__c>();
                
                //Map to hold Category related to Names
                Map<String, RevRecScheduleCategory__c> mapCatNamesWithCategories = new  Map<String, RevRecScheduleCategory__c>();
                
                //Checking for map size
                if(mapScheduleAccordingToMonthAndYear != null && mapMonthYearScheduleCategories != null)  {

                    //Loop over map to get mapKey
                    for(string str : mapScheduleAccordingToMonthAndYear.keySet()) {
                        
                        //Initilize map
                        mapCatNamesWithCategories = new  Map<String, RevRecScheduleCategory__c>();
                         
                        //Lopp over map to get schedules
                        for(RevRecScheduleCategory__c schCatg : mapMonthYearScheduleCategories.get(str)) {

                            //Populate schedule on RevCategory 
                            if(mapScheduleAccordingToMonthAndYear.get(str).Id != null) {
                                
                                //Populating schedule
                                schCatg.Schedule__c = mapScheduleAccordingToMonthAndYear.get(str).Id;
                                if(schCatg.Amount1__c != null)
                                    schCatg.Amt_Wei__c = (schCatg.Amount1__c * theOppty.Probability) / 100;
                                if(schCatg.Recognized_Amount__c != null)
                                    schCatg.Rec_Amt_Wei__c = (schCatg.Recognized_Amount__c * theOppty.Probability) / 100;
                                if(schCatg.Deferred_Amount__c != null)
                                schCatg.Def_Amt_Wei__c = (schCatg.Deferred_Amount__c * theOppty.Probability) / 100;
                                //Checking for map and populate map
                                
                                if(!mapCatNamesWithCategories.containsKey(schCatg.Category_Name__c))
                                    mapCatNamesWithCategories.put(schCatg.Category_Name__c, schCatg);
                                else {
                                    mapCatNamesWithCategories.get(schCatg.Category_Name__c).Amount1__c += schCatg.Amount1__c;
                                    mapCatNamesWithCategories.get(schCatg.Category_Name__c).Deferred_Amount__c += schCatg.Deferred_Amount__c  ;
                                }
                            }
                        }
                         //Checking for map size and put into map
                         if(mapCatNamesWithCategories.size() > 0)
                            listSchCategoryToBeInserted.addAll(mapCatNamesWithCategories.values());
                    }
                }
                
                //Checking for size and insert  list of schedule category
                if(listSchCategoryToBeInserted.size() > 0) {
                    
                    //Loop over category schedule
                    for(RevRecScheduleCategory__c schCat : listSchCategoryToBeInserted) {
                            
                        //Code modified - (07/10/2017) - Check if multi currency enabled in org or not
                        //If true the do this 
                        if(isMultiCurrencyEnabled) {
                            
                            //Checking for null
                            if(schCat.Deferred_Amount__c != null) {
                                schCat.Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), schCat.Deferred_Amount__c)).replace('<br/>', '');
                                schCat.Cor_Def_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), schCat.Deferred_Amount__c));
                            } else {
                                schCat.Converted_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                schCat.Cor_Def_Amt__c = 0.00;
                            }
                             //Checking for null
                            if(schCat.Amount1__c != null) {
                                schCat.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), schCat.Amount1__c)).replace('<br/>', '');
                                schCat.Cor_Rec_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), schCat.Amount1__c));
                            } else {
                                schCat.Converted_Recognized_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )'; 
                                schCat.Cor_Rec_Amt__c = 0.00;
                            }
                        }
                    }
                    
                    utilHelper.calSchCatWithCorporateField(listSchCategoryToBeInserted, theOppty, utl);
                    insert listSchCategoryToBeInserted;  
                }
                  
                //Re-initlization of the list of schedule category to be inserted
                listSchCategoryToBeInserted = new List<RevRecScheduleCategory__c>(); 
     
                //Query to get all blended schedules schedules and related categories 
                for(RevRecOpportunityLineItemSchedule__c schedule : [Select Id, Categories_List__c , (Select Id, Category_Name__c From RevRecScheduleCategorys__r)
                                                                    FROM RevRecOpportunityLineItemSchedule__c WHERE ID IN: allSchedules AND
                                                                    Rule_Type__c =: constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE]) {
                                                                        
                    //Set to hold the categories names  
                    Set<String> setCatNames = new Set<String>();
                    for(String  s : schedule.Categories_List__c.split(',')) 
                        setCatNames.add(s);
                    
                    //Checking if no any scheule created 
                    if(schedule.RevRecScheduleCategorys__r.size() == 0) {
                        
                        //Loop ovr set values
                        for(String catName : setCatNames) 
                            listSchCategoryToBeInserted.add(new RevRecScheduleCategory__c(Deferred_Amount__c = 0.00 , Amount1__c = 0.00, Amt_Wei__c = 0.00, Category_Name__c = catName, Schedule__c = schedule.Id));
                    }else {
                        
                        //Temp set to hold category names
                        Set<String> tempSetOfCat = new Set<String>();
                        tempSetOfCat = setCatNames;
                        
                        //Loop over Category Schedule records
                        for(RevRecScheduleCategory__c schCat : schedule.RevRecScheduleCategorys__r) {
                            
                            //Checking if category exist with that name then remove that name from set
                            if(tempSetOfCat.contains(schCat.Category_Name__c))
                                setCatNames.remove(schCat.Category_Name__c);
                        }
                        
                        //Loop over remaing catNames
                        for(String catName : setCatNames)
                            listSchCategoryToBeInserted.add(new RevRecScheduleCategory__c(Amount1__c = 0.00, Amt_Wei__c = 0.00, Category_Name__c = catName, Schedule__c = schedule.Id,Deferred_Amount__c = 0.00));
                    }
                }
                
                //Checking for size and insert  list of schedule category
                if(listSchCategoryToBeInserted.size() > 0) {
                     
                    for(RevRecScheduleCategory__c schCat : listSchCategoryToBeInserted) {
                        
                        //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                        //If true the do this 
                        if(isMultiCurrencyEnabled) {
                            
                            //Checking for null
                            if(schCat.Deferred_Amount__c != null) {
                                schCat.Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), schCat.Deferred_Amount__c)).replace('<br/>', '');
                                schCat.Cor_Def_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), schCat.Deferred_Amount__c));
                            } else {
                                schCat.Converted_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                schCat.Cor_Def_Amt__c = 0.00;
                            }
                             //Checking for null
                            if(schCat.Amount1__c != null) {
                                schCat.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), schCat.Amount1__c)).replace('<br/>', '');
                                schCat.Cor_Rec_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), schCat.Amount1__c));
                            } else {
                                schCat.Converted_Recognized_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )'; 
                                schCat.Cor_Rec_Amt__c = 0.00;
                            }
                        }
                    }
                    
                    utilHelper.calSchCatWithCorporateField(listSchCategoryToBeInserted, theOppty, utl);
                    insert listSchCategoryToBeInserted;       
                }               
            } catch (Exception exp) {
                
                //Calling method to create /update the error log while opportunity is calculating from the batch process
                if(IS_EXECUTING_BATCH)
                    utilHelper.createErrorLog(Id.ValueOf(theOppId) , exp);
                else
                    msg = exp.getLineNumber()+ exp.getStackTraceString() + 'Exception:' + exp.getMessage();
            }
        }catch (Exception e) { //Code added as per to create error log while batch is executing 
            
            //Calling method to create /update the error log while opportunity is calculating from the batch process
            if(IS_EXECUTING_BATCH)   
                utilHelper.createErrorLog(Id.ValueOf(theOppId) , e);
            else 
                msg = e.getLineNumber() + 'Exception:' + e.getStackTraceString();
        } 
        return msg; 
    }
    
     /** ~~~~~~~~~ Code added - 10/06/2015 - As per Blended Split Revenue Recognition ~~~~~~~~~ **/
    /**
     *  @description    :   This method is used to calculate the recognized and deferred amount for blended- Split revenue recognition
     *
     *  @return         :   CalculateBlendedWrapper
     * 
     *  @args           :   RevRecProductRuleCategory__c productCategory,
                            Decimal outstandingBalance, Decimal recognizedAmount, Decimal deferredAmount,
                            OpportunityLineItem lineitem, String msg, List<RevRecProductRuleCategory__c> listProductRuleCategories, 
                            List<RevRecProductRuleController.ProductRuleCategoryWrapper> prdWrap, Decimal actualDeferred,
                            Decimal amountToSplit
    **/  
    public static CalculateBlendedWrapper calculateRecAndDeferredRevForBlendedSplit (RevRecProductRuleCategory__c productCategory,
                                    Decimal outstandingBalance, Decimal recognizedAmount, Decimal deferredAmount,
                                    OpportunityLineItem lineitem, String msg, List<RevRecProductRuleCategory__c> listProductRuleCategories, 
                                    List<RevRecProductRuleController.ProductRuleCategoryWrapper> prdWrap, Decimal actualDeferred,
                                    Decimal amountToSplit , Decimal qtyToSplit, RevRecProductRule__c overrideRule) {
                                        
        //Initilize wrapper class  
        CalculateBlendedWrapper wrapCal = new CalculateBlendedWrapper();
              
        //Variables to handle Amortized rule
        Integer totalMonths ;
        Date endDateActual ;
        Date startDateActual;
        Decimal amountPerMonth;
        Decimal amountPerQty ;
        Decimal qtyPerMonth;
        Decimal percentPerMonth;
        Decimal totalAmountForQty ;
        Decimal lineItemAmount;
        Decimal amountToCalculateRecognized;
        Decimal actualCatDifference;
       
        //Checiing for null
        if(productCategory != null) { 
            
            //Initilize variables
            totalMonths = 0;
            amountPerMonth = 0.00;
            qtyPerMonth = 0.00;
            amountPerQty = 0.00;
            totalAmountForQty = 0.00;
            percentPerMonth = 0.00; 
            amountToCalculateRecognized = 0.00;
            actualCatDifference = 0.00;
            
            //Checking for Line item Number
            if(String.isNotBlank(productCategory.Line_Item__c)) {
                
                //Calculate Line number
                Integer lineNumber = Integer.ValueOf(productCategory.Line_Item__c) - 1;
                
                //If line item number is 0 , Use Opportunity Line item amount
                if(productCategory.Line_Item__c == '0')
                    amountToCalculateRecognized = amountToSplit;
                else {
                   
                    //Checking for Null.
                    if(listProductRuleCategories != null && listProductRuleCategories.size() > 0) {
                        amountToCalculateRecognized = listProductRuleCategories[lineNumber].Deferred_Amount__c;
                    }else if(prdWrap != null) {
                        amountToCalculateRecognized = prdWrap[lineNumber].revRecProductCategory.Deferred_Amount__c;
                    }
                }
            }
            //Calculation for Recognized and Deferred Revenue 
            //1.If Single Transaction
            if(productCategory.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                                     
                 //Checking for percent / Qty and Amount and calculate Recognized and Deferred amount
                if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_PERCENT && productCategory.Percent__c != null)
                    recognizedAmount = (amountToCalculateRecognized * productCategory.Percent__c)/100;
                else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_QTY && productCategory.Qty__c != null) {
                
                    recognizedAmount = ((amountToCalculateRecognized)/qtyToSplit)* productCategory.Qty__c; 
                }
                else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_AMOUNT && productCategory.Amount__c != null)
                    recognizedAmount = productCategory.Amount__c;
                
                //Code added- on 30 march - BUG 9 FIX
                actualCatDifference = recognizedAmount;
                
                //Checking for Actual start date
                if(productCategory.Actual_Start_Date__c != null && productCategory.Actual_Start_Date__c <= Date.Today()) {
                    //Deferred amount
                    deferredAmount = (amountToSplit - recognizedAmount );
                    actualDeferred = 0.00;
                    recognizedAmount = recognizedAmount; 
                    
                }else {
                     //In case of single transaction If no any recognozation yet then deffered amount is set to previous one
                     deferredAmount = (amountToSplit - recognizedAmount); 
                     actualDeferred = (recognizedAmount );
                     recognizedAmount = 0.00;
                }       
            }else if(productCategory.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE) {
                
                //Decimal total Amount
                Decimal totalAmount = 0.00;
                
                //Checking for Amount / Qty and Percent 
                if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_AMOUNT && productCategory.Amount__c != null) {
                    
                    amountPerMonth = productCategory.Amount__c;
                    totalAmount = amountPerMonth;
                   
                }else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_QTY && productCategory.Qty__c != null) {
                    amountPerQty =  amountToCalculateRecognized / qtyToSplit;
                    totalAmountForQty = amountPerQty * productCategory.Qty__c;
                    totalAmount = totalAmountForQty;
                    
                }else if(productCategory.Category_Type__c == Constants.RULE_CATEGORY_TYPE_PERCENT && productCategory.Percent__c != null) {
                    
                    percentPerMonth = (productCategory.Percent__c * amountToCalculateRecognized)/ 100;
                    totalAmount = percentPerMonth;
                }
                
                //Code added on 30 March 2016 - 9 BUG FIX 2016
                actualCatDifference =  totalAmount; 
                deferredAmount = amountToSplit - totalAmount;
                
                //Checking for Actual start date and Actual end Date Not Null
                if(productCategory.Actual_Start_Date__c != null && productCategory.Actual_End_Date__c != null) {
                    
                    //Getting start and end date from category 
                    startDateActual = productCategory.Actual_Start_Date__c;
                    endDateActual = productCategory.Actual_End_Date__c;
                    
                    //Checking for any of the date not null
                    if(endDateActual != null || startDateActual != null) {
                   
                        //Checking for end date greater than start date  and Getting total months between start and end date
                        if( endDateActual >= startDateActual) {
                        
                            //Added on 03/20/2018
                            RevRecUtilHelper utilHelper = new RevRecUtilHelper();
                            List<Decimal> recognizableForEachMonthsForBR = new List<Decimal>();

                            //Total months
                            totalMonths = Integer.ValueOf(startDateActual.MonthsBetween(endDateActual)) ;
                            totalMonths = utilHelper.getTotalMonths(startDateActual, endDateActual, totalMonths, overrideRule);
                            recognizableForEachMonthsForBR = utilHelper.getRecognigibleFORBR(startDateActual, endDateActual, overrideRule, 
                                                                                             totalAmount, totalMonths, 
                                                                                             recognizableForEachMonthsForBR);
                            Date tempDate = startDateActual.addMonths(totalMonths);
                            
                            //Checking for total months
                            if(tempDate.daysBetween(endDateActual) >= 0)
                                totalMonths = totalMonths+1;
                             
                            //Checking for months
                            if(totalMonths != null) {
                                
                                //Month Difference between 
                                Boolean inCurrentMonth = IsInCurrentMonthForBlended(startDateActual);
                                Integer recognizedMonth = 0;
                                Date transDate = getTransDateForBlended(startDateActual , inCurrentMonth);
                                
                                for(Integer i=1; i<= (totalMonths - 1) ; i++) {
                                    
                                    if(transDate <= Date.today())   //-----------------------------
                                        recognizedMonth = recognizedMonth + 1;
                                    
                                    //Add one month in transaction date
                                    transDate = transDate.addMonths(1);
                                }
                                if(recognizedMonth > 0) {
                                    
                                    //Calculation for Recognized and deferred
                                    for(Integer count=0; count < recognizedMonth; count++) {
                                        
                                        if(recognizableForEachMonthsForBR.size() > 0) 
                                            recognizedAmount += recognizableForEachMonthsForBR[count];
                                    }   
                                }
                                actualDeferred = (totalAmount - recognizedAmount );
                           }
                        }else {
                            //Deferred amount
                            actualDeferred = (totalAmount - recognizedAmount );
                                
                            //Error message to show on page 
                            msg += 'End date must be greater than start Date for Category "' + productCategory.Name + '"'; 
                        } 
                    }else 
                        actualDeferred = (totalAmount - recognizedAmount );
               }else //Deferred amount
                    actualDeferred = (totalAmount - recognizedAmount );
            }
        }
        
        //Populate wrapper
        wrapCal.outStandingBalance = amountToSplit;
        wrapCal.msg = msg;
        wrapCal.recognizedAmount = recognizedAmount;
        wrapCal.deferredAmount = deferredAmount;
        wrapCal.actualDeferred = actualDeferred;
        wrapCal.actualCatDifference = actualCatDifference;

        return wrapCal;
    }
                                    
    private Boolean IsInCurrentMonth (Date startDate){
        Boolean startInCurrentMonth = true;
        if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                    // do nothing
        } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
            Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
            if (startDate.day() > settingDateInTheMonth) {
                startInCurrentMonth = false;
            }
        } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
            Date certainWeekCertainWeekdayForStartDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (startDate > certainWeekCertainWeekdayForStartDate) 
                startInCurrentMonth = false;
        }
        return startInCurrentMonth;
    }
    
    private string RecognizeForMilestones(Integer sequence, Double recognizableTotal, string MilestoneType,
                                            OpportunityLineItem lineItem,RevRecOpportunityLineItem__c revreclineItem,
                                            List<RevRecProductRuleMilestone__c> productMilestones,
                                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules,
                                            Opportunity oppty){ 
                                                                                      
        string result = '';
        Double recognizedTotal = 0;
        Boolean startInCurrentMonth = true;
        
        //recognizableTotal
        Date now = Date.today();
        double monthlyAccumulated = 0;
        Decimal deferredRevenueAmount = 0.00;
        Decimal forecastedRevenueAmount = 0.00;
        
        //List of milestones
        List<RevRecProductRuleMilestone__c> miles = new List<RevRecProductRuleMilestone__c>();
        Integer totalMileStones = 0;
        RevRecProductRule__c revRecRule = new RevRecProductRule__c(Name = 'Test' , RevRecOpportunityLineItem__c = revreclineItem.Id);

        if(productMilestones != null) {
            miles = productMilestones;
            //Total miles
            totalMileStones = miles.size();
        }
        
        Date lastMileDate ;
        //Loop over milestones
        for (Integer i= 0; i < totalMileStones; i++) {
            
            //Instance of schedules
            RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
            
            //Assign ReverecLine item id to schedules
            theSchedule.OpportunityLineItemId__c = lineItem.Id;
            
              //Code modified - (1/8/2015) - Check if multi currency enabled then do this  
              if(isMultiCurrencyEnabled)
                    theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
            
            //Checking for milestone date
            RevRecProductRuleMilestone__c currentMilestone = miles[i];
            //Decimal currentAmt = currentMilestone.Amount__c != null ?  currentMilestone.Amount__c : 0.00;
            Decimal currentAmt = currentMilestone.Actual_Amount__c != null ?  currentMilestone.Actual_Amount__c : 0.00;
            revreclineItem.Allocated__c = revreclineItem.Allocated__c != null ? revreclineItem.Allocated__c + currentAmt : currentAmt ;
            if (currentMilestone.Milestone_Date__c == null)
                continue;
         
            //If milestone type 
            if (MilestoneType.equalsIgnoreCase('amount')) {
                if( currentMilestone.Actual_Amount__c != null)
                    //theSchedule.RecognizedRev__c = currentMilestone.Amount__c;
                    theSchedule.RecognizedRev__c = currentMilestone.Actual_Amount__c;
                else                                              
                    theSchedule.RecognizedRev__c = 0.00;
                    
                //------------------- New Enhancement for Forecasted Revenue
                if( currentMilestone.Amount__c != null)
                    theSchedule.ForecastedRev__c = currentMilestone.Amount__c;
                else                                              
                    theSchedule.ForecastedRev__c = 0.00;
                    
            } else if (MilestoneType.equalsIgnoreCase('qty')) { 
                if( currentMilestone.Actual_Qty__c != null) 
                    //theSchedule.RecognizedRev__c = currentMilestone.Amount__c;
                    theSchedule.RecognizedRev__c = currentMilestone.Actual_Amount__c;
                else                                                
                    theSchedule.RecognizedRev__c = 0.00;
                    
                //------------------- New Enhancement for Forecasted Revenue
                if( currentMilestone.Amount__c != null)
                    theSchedule.ForecastedRev__c = currentMilestone.Amount__c;
                else                                              
                    theSchedule.ForecastedRev__c = 0.00;
                    
            }else {
                if ( currentMilestone.Actual_Percent__c != null)  
                    theSchedule.RecognizedRev__c = recognizableTotal * currentMilestone.Actual_Percent__c/100.0;
                else                                                
                    theSchedule.RecognizedRev__c = 0.00;
                    
                //------------------- New Enhancement for Forecasted Revenue
                if( currentMilestone.Percent__c != null) 
                    theSchedule.ForecastedRev__c = recognizableTotal * currentMilestone.Percent__c/100.0;
                else                                              
                    theSchedule.ForecastedRev__c = 0.00;
            }

            if(theSchedule.RecognizedRev__c != null)
                if(lineItem.TotalPrice == 0)
                    theSchedule.Recognized_Quantity__c = 0;
                else
                    theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100;
            
            theSchedule.Date__c = currentMilestone.Milestone_Date__c;
            theSchedule.OriginalDate__c = currentMilestone.Milestone_Date__c;
            theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
            lastMileDate  = currentMilestone.Milestone_Date__c;
            //decide the month of recognize
            if (theSetting.Time_of_Month_Selection_Types__c == '1')  //last day of the month
                startInCurrentMonth = true;
            else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
                Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
                
                if (currentMilestone.Milestone_Date__c.day() > settingDateInTheMonth)
                    startInCurrentMonth = false;
            } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
                Date settingDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theSchedule.Date__c, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                if (currentMilestone.Milestone_Date__c > settingDate) 
                    startInCurrentMonth = false;
            } 
            
            if(theSchedule.RecognizedRev__c != null)
                monthlyAccumulated += theSchedule.RecognizedRev__c;
          
            theSchedule.DeferredRev__c = recognizableTotal - monthlyAccumulated;
            if(!Test.isRunningTest())
                if(theSchedule.RecognizedRev__c != null) //Added on 03/05/2018 for Issue #4 
                    theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability) / 100;
            theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
            deferredRevenueAmount = theSchedule.DeferredRev__c;
            //-----------------
            forecastedRevenueAmount += theSchedule.ForecastedRev__c;
            
            if (theSchedule.OriginalDate__c <= now) {
                if(theSchedule.RecognizedRev__c != null)
                    recognizedTotal +=  theSchedule.RecognizedRev__c;
            }
            
            theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
            theSchedule.Sequence__c = i + 1 ;                      
            theSchedule.RecognizedRevTotal__c = monthlyAccumulated;
            theSchedule.Rec_Total_Amt_Wei__c = (monthlyAccumulated * oppty.Probability) / 100;
            theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
            theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice; 
            theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
            revenuSchedules.add(theSchedule);  
        }
        /*
        As per the requirement if deferredRevenueAmount is greater than 1 then this condition will run
        */                                               
        if(lastMileDate != null && deferredRevenueAmount > 1 ) { 
            for (Integer j=1; j <= 12; j++) {
                RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                theSchedule.OpportunityLineItemId__c = lineItem.Id;
                theSchedule.OriginalDate__c = lastMileDate.addMonths(j);
                theSchedule.Date__c = theSchedule.OriginalDate__c;
                theSchedule.RecognizedRev__c = 0;
                theSchedule.Recognized_Quantity__c = 0;
                theSchedule.DeferredRev__c = deferredRevenueAmount;
                theSchedule.RecRevWei__c = 0;
                theSchedule.DefReWei__c = (deferredRevenueAmount*oppty.Probability) / 100;
                theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                theSchedule.Sequence__c = 0;
                theSchedule.RecognizedRevTotal__c = 0;
                theSchedule.Rec_Total_Amt_Wei__c = 0;
                theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
                theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice;  
                theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
                
                //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                if(isMultiCurrencyEnabled)
                    theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));                            
                   
                revenuSchedules.add(theSchedule);
            }
         }
        revreclineItem.RecognizedRev__c = recognizedTotal;
        revreclineItem.DeferredRev__c = recognizableTotal - revreclineItem.RecognizedRev__c;
        revreclineItem.RecRevWei__c = (recognizedTotal * oppty.Probability) / 100;
        revreclineItem.DefReWei__c = (revreclineItem.DeferredRev__c * oppty.Probability) / 100;
        revreclineItem.CalculatedAt__c = date.today();
        revreclineItem.TotalRev__c = recognizableTotal;
        revreclineItem.Total_Amt_Wei__c = (recognizableTotal * oppty.Probability) / 100; 
        
        //----------------------New Enhancements for Forecast Revenue 
        revreclineItem.ForecastedRev__c = forecastedRevenueAmount;
        revreclineItem.ForeRevWei__c = (revreclineItem.ForecastedRev__c * oppty.Probability) / 100;
        if(lineItem.TotalPrice > 0)
            revreclineItem.Allocated__c = ((revreclineItem.Allocated__c != null  ? revreclineItem.Allocated__c : 0.00) * 100 ) /lineItem.TotalPrice;
        else
            revreclineItem.Allocated__c = 0.00;                                                
        return result;                  
    }
    
     public string YearlyAmortized(RevRecProductRule__c overrideRule, Integer sequence, Double recognizableTotal, double initial, 
                                            Date startDate, Date endDate, 
                                            Opportunity oppty, OpportunityLineItem lineItem,RevRecOpportunityLineItem__c revrecLineItem,
                                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules){
        string result = '';
        Double recognizedTotal = 0;

        if(endDate != null) {
            Integer totalMonth = startDate.monthsBetween(endDate);
            if (startDate.day() <= endDate.day()) totalMonth++;
            Boolean startInCurrentMonth = true;
            if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                        // do nothing
            } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
                Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
                if (startDate.day() > settingDateInTheMonth) {
                    totalMonth--; 
                    startInCurrentMonth = false;
                }
                if (endDate.day() >  settingDateInTheMonth) 
                    totalMonth++;               
            } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
                Date certainWeekCertainWeekdayForStartDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                if (startDate > certainWeekCertainWeekdayForStartDate) {
                    totalMonth--; 
                    startInCurrentMonth = false;
                }
                Date certainWeekCertainWeekdayForEndDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(endDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                if (endDate >  certainWeekCertainWeekdayForEndDate) 
                    totalMonth++;               
            } 
            
            Integer totalYears = (totalMonth -1)/12 + 1;
            double yearlyRecognizable= (recognizableTotal-initial)/totalYears;
            
            Date initialDate = startDate;
            Date now = Date.today();
            double yearlyAccumulated = 0;
            for (Integer i=0; i < totalYears; i++) {
                RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                theSchedule.OpportunityLineItemId__c = lineItem.Id;
                
                //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                if(isMultiCurrencyEnabled)
                    theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                
                theSchedule.OriginalDate__c = initialDate.addYears(i);
                theSchedule.Date__c = utilHelper.GetTransDate(initialDate.addYears(i), startInCurrentMonth, theSetting);
                theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
    
                if (i== 0) 
                    theSchedule.RecognizedRev__c = yearlyRecognizable + initial;
                else if (i == totalMonth -1 )
                    theSchedule.RecognizedRev__c = recognizableTotal - yearlyAccumulated;
                else 
                    theSchedule.RecognizedRev__c = yearlyRecognizable;
                
                yearlyAccumulated += theSchedule.RecognizedRev__c;
                theSchedule.DeferredRev__c = recognizableTotal - yearlyAccumulated;
                theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
                theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability) / 100;
                                            
                if (theSchedule.Date__c <= now) 
                    recognizedTotal +=  theSchedule.RecognizedRev__c;
                theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                theSchedule.Sequence__c = i + 1 ;                                                
                
                theSchedule.RecognizedRevTotal__c = yearlyAccumulated;
                theSchedule.Rec_Total_Amt_Wei__c = (yearlyAccumulated * oppty.Probability) / 100;
                theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
                theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice; 
                theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
                if(lineItem.TotalPrice == 0)
                    theSchedule.Recognized_Quantity__c = 0;
                else    
                    theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100;  
                
                revenuSchedules.add(theSchedule); 
                    
                if (i != totalYears -1) {
                    for (Integer j = 1; j < 12 ; j++) {
                        RevRecOpportunityLineItemSchedule__c theSchedule1 = new RevRecOpportunityLineItemSchedule__c();
                        theSchedule1.OpportunityLineItemId__c = lineItem.Id;
                        theSchedule1.OriginalDate__c = theSchedule.OriginalDate__c.addMonths(j);
                        theSchedule1.Date__c = theSchedule.Date__c.addMonths(j);
                        theSchedule1.Month__c = theSchedule1.Date__c.month() +'' ;
                        theSchedule1.RecognizedRev__c = 0;
                        theSchedule1.Recognized_Quantity__c = 0;
                        theSchedule1.DeferredRev__c = theSchedule.DeferredRev__c;
                        theSchedule1.RecRevWei__c = 0;
                        theSchedule1.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
                        theSchedule1.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                        theSchedule1.Sequence__c = i + 1 ;                     
                        
                        //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                        if(isMultiCurrencyEnabled)
                            theSchedule1.put('CurrencyIsoCode', theSchedule.get('CurrencyIsoCode'));
                  
                        theSchedule1.RecognizedRevTotal__c = theSchedule.RecognizedRevTotal__c;
                        theSchedule1.Rec_Total_Amt_Wei__c = (theSchedule.RecognizedRevTotal__c * oppty.Probability) / 100;
                        theSchedule1.ResidualAmountTotal__c = theSchedule.ResidualAmountTotal__c;
                        theSchedule1.LineItemAmountTotal__c = theSchedule.LineItemAmountTotal__c;  
                        theSchedule1.LI_Amt_Total_Wei__c = (theSchedule.LineItemAmountTotal__c * oppty.Probability) / 100;
                        revenuSchedules.add(theSchedule1); 
                    }
                } 
            }
            revreclineItem.RecognizedRev__c = recognizedTotal;
            revreclineItem.DeferredRev__c = recognizableTotal - revreclineItem.RecognizedRev__c;
            revreclineItem.RecRevWei__c = (recognizedTotal * oppty.Probability) / 100;
            revreclineItem.DefReWei__c = (revreclineItem.DeferredRev__c * oppty.Probability) / 100;
            revreclineItem.CalculatedAt__c = date.today();
            revreclineItem.TotalRev__c = recognizableTotal;
            revreclineItem.Total_Amt_Wei__c = (recognizableTotal  * oppty.Probability) / 100;
        }
        return result;                  
    }
    
    public string QuartlyAmortized(RevRecProductRule__c overrideRule, Integer sequence, Double recognizableTotal, double initial, String DevidedByType,
                                            Date startDate, Date endDate,
                                            Opportunity oppty, OpportunityLineItem lineItem, RevRecOpportunityLineItem__c revrecLineItem,
                                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules){
        string result = '';
        Double recognizedTotal = 0;
        
        if(endDate != null) {
            Integer totalMonth = startDate.monthsBetween(endDate);
            if (startDate.day() <= endDate.day()) totalMonth++;
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            Boolean startInCurrentMonth = true;
            if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                        // do nothing
            } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
                Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
                if (startDate.day() > settingDateInTheMonth) {
                    totalMonth--; 
                    startInCurrentMonth = false;
                }
                if (endDate.day() >  settingDateInTheMonth)
                    totalMonth++;               
            } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
                Date certainWeekCertainWeekdayForStartDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                if (startDate > certainWeekCertainWeekdayForStartDate) {
                    totalMonth--; 
                    startInCurrentMonth = false;
                }
                Date certainWeekCertainWeekdayForEndDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(endDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                if (endDate >  certainWeekCertainWeekdayForEndDate) 
                    totalMonth++;               
            }
            
            double dailyRecognizable= (recognizableTotal-initial)/totalDays;
            integer totalPeriod = (totalMonth - 1) / 3 + 1;
            double periodRecognizable = 0;
            periodRecognizable= (recognizableTotal-initial)/totalPeriod;
                      
            Date initialDate = startDate;
            Date now = Date.today();
            double periodAccumulated = 0;
            for (Integer i=0; i < totalPeriod; i++) {
                RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                theSchedule.OpportunityLineItemId__c = lineItem.Id;
                
               //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                if(isMultiCurrencyEnabled)
                    theSchedule.put('CurrencyIsoCode', oppty.get('CurrencyIsoCode'));
                  
                theSchedule.OriginalDate__c = initialDate.addMonths(i * 3);
                theSchedule.Date__c = utilHelper.GetTransDate(initialDate.addMonths(i * 3), startInCurrentMonth, theSetting);
                theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
    
                Integer totalDaysInPeriod = initialDate.addMonths(i * 3 ).daysBetween(initialDate.addMonths((i+1) * 3));
                if (i== 0) {
                    if (DevidedByType == 'period')
                        theSchedule.RecognizedRev__c = periodRecognizable + initial;
                    else 
                        theSchedule.RecognizedRev__c = dailyRecognizable * totalDaysInPeriod + initial;
                }   
                else if (i == totalPeriod -1 )
                    theSchedule.RecognizedRev__c = recognizableTotal - periodAccumulated;
                else {
                    if (DevidedByType == 'period')
                        theSchedule.RecognizedRev__c = periodRecognizable;
                    else 
                        theSchedule.RecognizedRev__c = dailyRecognizable * totalDaysInPeriod ;
                }
                periodAccumulated += theSchedule.RecognizedRev__c;
                theSchedule.DeferredRev__c = recognizableTotal - periodAccumulated;
                             
                if (theSchedule.Date__c <= now) 
                    recognizedTotal +=  theSchedule.RecognizedRev__c;
                theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                theSchedule.Sequence__c = i + 1; 
                theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability) / 100;
                theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
                theSchedule.RecognizedRevTotal__c = periodAccumulated;
                theSchedule.Rec_Total_Amt_Wei__c = (periodAccumulated * oppty.Probability) / 100;
                theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
                theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice;  
                theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
                if(lineItem.TotalPrice == 0)
                    theSchedule.Recognized_Quantity__c = 0;
                else    
                    theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100;
                
                revenuSchedules.add(theSchedule);  
                
                if (i != totalPeriod -1) {
                
                    for (Integer j = 1; j < 3 ; j++) {
                
                        RevRecOpportunityLineItemSchedule__c theSchedule1 = new RevRecOpportunityLineItemSchedule__c();
                        theSchedule1.OpportunityLineItemId__c = lineItem.Id;
                        theSchedule1.OriginalDate__c = theSchedule.OriginalDate__c.addMonths(j);
                        theSchedule1.Date__c = theSchedule.Date__c.addMonths(j);
                        theSchedule1.Month__c = theSchedule1.Date__c.month() +'' ;
                        theSchedule1.RecognizedRev__c = 0;
                        theSchedule1.RecRevWei__c = 0;
                        theSchedule.Recognized_Quantity__c = 0;
                        theSchedule1.DeferredRev__c = theSchedule.DeferredRev__c;
                        theSchedule1.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
                        theSchedule1.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                        theSchedule1.Sequence__c = theSchedule.Sequence__c;
    
                        //Code modified - (1/8/2015) - Check if multi currency enabled then do this
                        if(isMultiCurrencyEnabled)
                            theSchedule1.put('CurrencyIsoCode', theSchedule.get('CurrencyIsoCode'));
                            
                        theSchedule1.RecognizedRevTotal__c = theSchedule.RecognizedRevTotal__c;
                        theSchedule1.Rec_Total_Amt_Wei__c = (theSchedule.RecognizedRevTotal__c  * oppty.Probability) / 100;
                        theSchedule1.ResidualAmountTotal__c = theSchedule.ResidualAmountTotal__c;
                        theSchedule1.LineItemAmountTotal__c = theSchedule.LineItemAmountTotal__c;   
                        theSchedule1.LI_Amt_Total_Wei__c = (theSchedule.LineItemAmountTotal__c * oppty.Probability) / 100;
                        revenuSchedules.add(theSchedule1); 
                    }
                }                                    
            }
    
            revreclineItem.RecognizedRev__c = recognizedTotal;
            revreclineItem.DeferredRev__c = recognizableTotal - revreclineItem.RecognizedRev__c;
            revreclineItem.RecRevWei__c = (recognizedTotal * oppty.Probability) / 100;
            revreclineItem.DefReWei__c = (revreclineItem.DeferredRev__c * oppty.Probability) / 100;
            revreclineItem.CalculatedAt__c = date.today();
            revreclineItem.TotalRev__c = recognizableTotal;
            revreclineItem.Total_Amt_Wei__c = (recognizableTotal * oppty.Probability) / 100;
        }
        return result;                  
    }
    
    /**
     *  @description    :   This method is used to check the month.
     *
     *  @args           :   Date startDate
     *
     *  @return         :   Boolean
    **/
    public static Boolean IsInCurrentMonthForBlended (Date startDate){
        
        //Boolean
        Boolean startInCurrentMonth = true;
        
        //Checking for the month
        if (appSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
        } else if (appSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
            
            Integer settingDateInTheMonth = Integer.valueOf(appSetting.Certain_date_of_month__c);
            
            if (startDate.day() > settingDateInTheMonth)
                startInCurrentMonth = false;
        } else if (appSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
            
            Date certainWeekCertainWeekdayForStartDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, appSetting.Certain_weekday__c, appSetting.Certain_weekday_day__c);
            
            if (startDate > certainWeekCertainWeekdayForStartDate)
                startInCurrentMonth = false;
        }
        return startInCurrentMonth;
    }
    
    /**
     *  @description    :   This method is used to get the transaction date.
     *
     *  @args           :   Date theDate, boolean inCurrentMonth
     *
     *  @return         :   Date
    **/
    private static Date GetTransDateForBlended(Date theDate, boolean inCurrentMonth) {
      
        Date returnDate = theDate;
        
        if (!inCurrentMonth) returnDate = returnDate.addMonths(1);
        
        //default is first day of the month
        Integer transactionDay = theDate.toStartOfMonth().day();
        
        if (appSetting.Time_of_Month_Selection_Types_tr__c == '1') //last day of the month
            transactionDay = theDate.addMonths(1).toStartOfMonth().addDays(-1).day();
            //transactionDay = Date.daysInMonth(returnDate.year(), transactionMonth);
        else if (appSetting.Time_of_Month_Selection_Types_tr__c == '2') // Date of the month
            transactionDay = Integer.valueOf(appSetting.Certain_date_of_month_tr__c);
        else if (appSetting.Time_of_Month_Selection_Types_tr__c == '3') { //certain weekday of certain week
            Date calculated = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, appSetting.Certain_weekday_tr__c, appSetting.Certain_weekday_day_tr__c);
            transactionDay = calculated.day();
        }
        returnDate = date.newinstance(returnDate.year(), returnDate.month(), transactionDay);
        
        return returnDate;
    }   
    
     //Code added - 11/12/2014 - method added for "Amortize MileStone"
    //The recognized and deferred revenue should be based on the actual not the forecasted
    private string RecognizeForAmortizeMilestones(Integer sequence, Double recognizableTotal, string amortizeBy,  
                                            OpportunityLineItem lineItem,RevRecOpportunityLineItem__c revreclineItem,
                                            List<RevRecProductRuleMilestone__c> productMilestones,
                                            List<RevRecOpportunityLineItemSchedule__c> revenuSchedules,
                                            Opportunity oppty, Double residualTotal, Double totalRev, Date oppCloseDate, Id productRuleId, String divideBy) {   
        //recognizableTotal
        Date now = Date.today();
        Date startDate;
        Date endDate;
        Double monthlyAccumulated = 0;
        Integer totalMileStones = productMilestones.size();               
        
        //Getting start and end dates from First and last milestone
        if (productMilestones != null && productMilestones.size() > 0 && productMilestones[0].Milestone_Date__c != null && 
            productMilestones[totalMileStones -1 ].Milestone_Date__c != null) {
            startDate = productMilestones[0].Milestone_Date__c;
            endDate = productMilestones[totalMileStones -1 ].Milestone_Date__c;
        } else { // If milestone date null then start and end date null
            startDate = null;
            endDate = null;
       }
       
       List<RevRecOpportunityLineItemSchedule__c> revenuSchedulesCopy = new List<RevRecOpportunityLineItemSchedule__c>();
        
        //If start date == Null
        if (startDate == null) {
            
            //Loop to create 12 month schedule
            for (Integer j=0; j < 12; j++) {
                RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
                theSchedule.OpportunityLineItemId__c = lineItem.Id;
                theSchedule.OriginalDate__c = oppty.CloseDate.addMonths(j);
                theSchedule.Date__c = theSchedule.OriginalDate__c;
                theSchedule.RecognizedRev__c = 0;
                theSchedule.RecRevWei__c = 0;
                theSchedule.Recognized_Quantity__c = 0;
                theSchedule.DeferredRev__c = recognizableTotal;
                theSchedule.DefReWei__c = (recognizableTotal * oppty.Probability) / 100;
                theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
                theSchedule.Sequence__c = 0;
                theSchedule.RecognizedRevTotal__c = 0;
                theSchedule.Rec_Total_Amt_Wei__c = 0;
                theSchedule.ResidualAmountTotal__c = residualTotal;
                theSchedule.LineItemAmountTotal__c = totalRev;   
                theSchedule.LI_Amt_Total_Wei__c = (totalRev * oppty.Probability) / 100;
            
                //Code modified - (1/08/2015) - Check if multi currency enabled then do this
                if(isMultiCurrencyEnabled)
                    theSchedule.put('CurrencyIsoCode' , oppty.get('CurrencyIsoCode'));           
                
                //Add schedule into list
                revenuSchedulesCopy.add(theSchedule);
            }
        } 
         //Variables
        string result = '';
        Decimal recognizedTotal = 0;
        Boolean startInCurrentMonth = true;
        Decimal recognizedTotalForREvRec = 0.00;
        Decimal deferredTotalForREvRec = 0.00;
        Decimal totalAMForAllMonths = 0.00;
        Decimal forecastedTotalForREvRec = 0.00;
        
        if(startDate != null ) {
            if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                    // do nothing
            } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
                Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
                if (startDate.day() > settingDateInTheMonth)
                    startInCurrentMonth = false;
            } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
                Date certainWeekCertainWeekdayForStartDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                if (startDate > certainWeekCertainWeekdayForStartDate)
                    startInCurrentMonth = false;
            }
        }
        
        //Instance of current milestone  
        RevRecProductRuleMilestone__c currentMilestone = new RevRecProductRuleMilestone__c();
        Set<String> strMileName = new Set<String>();
                                 
        //Loop over total milestones
        for (Integer i= 0; i <totalMileStones; i++) {
            
            //Instance of schedules
            RevRecOpportunityLineItemSchedule__c theSchedule = new RevRecOpportunityLineItemSchedule__c();
            
            //Assign Line Item id to schedule
            theSchedule.OpportunityLineItemId__c = lineItem.Id;
            
            //Code modified - (1/08/2015) - Check if multi currency enabled then do this
            if(isMultiCurrencyEnabled)
                theSchedule.put('CurrencyIsoCode' , oppty.get('CurrencyIsoCode'));
            
            //Checking for milestone size
            if(productMilestones.size() > 0)
                 currentMilestone = productMilestones[i];
            if (currentMilestone.Milestone_Date__c == null)
                continue;
            if(strMileName.contains(currentMilestone.Name))
                continue;
                
             strMileName.add(currentMilestone.Name);
                
            //Checking for Amortize by = Amount
            if (amortizeBy.equalsIgnoreCase('amount')) {
                
                //Checking for conditions
                if( currentMilestone.Actual_Amount__c != null )
                    theSchedule.RecognizedRev__c = currentMilestone.Actual_Amount__c;
                else 
                    theSchedule.RecognizedRev__c = recognizedTotal;
                    
                //Calculation for forecasted values 
                //Checking for conditions
                if( currentMilestone.Amount__c != null )
                    theSchedule.ForecastedRev__c = currentMilestone.Amount__c;
                else 
                    theSchedule.ForecastedRev__c = 0.00;
            
            //Checking for Amortize By = QTY
            } else if (amortizeBy.equalsIgnoreCase('qty')) {
                //Checking for conditions
                if( currentMilestone.Actual_Qty__c != null )
                     theSchedule.RecognizedRev__c = recognizableTotal * currentMilestone.Actual_Qty__c/lineItem.quantity; 
                else if( currentMilestone.Actual_Amount__c != null )
                    theSchedule.RecognizedRev__c = currentMilestone.Actual_Amount__c;
                else 
                    theSchedule.RecognizedRev__c = recognizedTotal;
                    
                //Calculation for Forecaseted Revenue
                //Checking for conditions
                if( currentMilestone.Qty__c != null )
                     theSchedule.ForecastedRev__c = recognizableTotal * currentMilestone.Qty__c/lineItem.quantity; 
                else if( currentMilestone.Amount__c != null )
                    theSchedule.ForecastedRev__c = currentMilestone.Amount__c;
                else 
                    theSchedule.ForecastedRev__c = 0.00;
            } else {
                if ( currentMilestone.Actual_Percent__c != null)  
                    theSchedule.RecognizedRev__c = recognizableTotal * currentMilestone.Actual_Percent__c/100.0;
                else if( currentMilestone.Actual_Amount__c != null )
                    theSchedule.RecognizedRev__c = currentMilestone.Actual_Amount__c;
                else 
                    theSchedule.RecognizedRev__c = recognizedTotal;
                    
                //Calculation for Forecasted Revenue
                if ( currentMilestone.Percent__c != null)  
                    theSchedule.ForecastedRev__c = recognizableTotal * currentMilestone.Percent__c/100.0;
                else if( currentMilestone.Amount__c != null )
                    theSchedule.ForecastedRev__c = currentMilestone.Amount__c;
                else 
                    theSchedule.ForecastedRev__c = 0.00;
            }
                        
            //Populate fields on schedule        
            theSchedule.Date__c = utilHelper.GetTransDate(currentMilestone.Milestone_Date__c, startInCurrentMonth, theSetting);
            theSchedule.OriginalDate__c =  theSchedule.Date__c ;
            theSchedule.Month__c = theSchedule.Date__c.month() +'' ;
            if(lineItem.TotalPrice == 0)
                theSchedule.Recognized_Quantity__c = 0;
            else
                theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100;
            
            //Monthly accumlated
            monthlyAccumulated += theSchedule.RecognizedRev__c;
                        
            //Added a condition for last schedule residual amount
            //Added on 2nd August 2016 - CPU time limit exceed issue
            if(LineItem.TotalPrice == 0.00) {
                theSchedule.DeferredRev__c = 0.00;
                theSchedule.RecognizedRev__c = 0.00;
                monthlyAccumulated = 0.00;
            } else {
                if(i == totalMileStones-1 && LineItem.TotalPrice - monthlyAccumulated <= 10)  {  
                    theSchedule.DeferredRev__c = 0.00;
                    theSchedule.RecognizedRev__c = theSchedule.RecognizedRev__c + (LineItem.TotalPrice - monthlyAccumulated);
                    monthlyAccumulated = monthlyAccumulated + (Math.abs(LineItem.TotalPrice - monthlyAccumulated));
                }
                else                
                    theSchedule.DeferredRev__c = Math.abs(recognizableTotal - monthlyAccumulated);
            }
             
            //Checking for Amortize by = 'Amount'
            if (amortizeBy.equalsIgnoreCase('amount')) {
                if( currentMilestone.Actual_Amount__c != null) {
                    if(theSchedule.Date__c <= Date.Today()) 
                        recognizedTotalForREvRec += currentMilestone.Actual_Amount__c;
                    else
                        deferredTotalForREvRec += currentMilestone.Actual_Amount__c;
                }
                
                //Calculation for Forecasted Revenue
                if( currentMilestone.Amount__c != null) {
                    forecastedTotalForREvRec += currentMilestone.Amount__c;
                }
                
                if(LineItem.TotalPrice == 0.00) {
                    revreclineItem.Allocated__c = 0.00;
                } else {
                    if(currentMilestone.Actual_Amount__c != null)
                        revreclineItem.Allocated__c = revreclineItem.Allocated__c != null ? revreclineItem.Allocated__c + ((currentMilestone.Actual_Amount__c*100)/LineItem.TotalPrice) :  ((currentMilestone.Actual_Amount__c*100)/LineItem.TotalPrice);
                }
                //Amortize By = Qty  
            } else if (amortizeBy.equalsIgnoreCase('qty')) {
                if(theSchedule.Date__c <= Date.Today()) {
                    if( currentMilestone.Actual_Qty__c != null) 
                        recognizedTotalForREvRec += recognizableTotal * currentMilestone.Actual_Qty__c/lineItem.quantity; 
                    else if( currentMilestone.Actual_Amount__c != null && theSchedule.Date__c <= Date.Today())
                        recognizedTotalForREvRec += currentMilestone.Actual_Amount__c;
                }
                else {
                    if( currentMilestone.Actual_Qty__c != null) 
                        deferredTotalForREvRec += recognizableTotal * currentMilestone.Actual_Qty__c/lineItem.quantity; 
                    else if( currentMilestone.Actual_Amount__c != null && theSchedule.Date__c <= Date.Today())
                        deferredTotalForREvRec += currentMilestone.Actual_Amount__c;
                }
                   
                if(LineItem.TotalPrice == 0.00) {
                    revreclineItem.Allocated__c = 0.00;
                } else {
                    if(currentMilestone.Actual_Qty__c != null)
                        revreclineItem.Allocated__c = revreclineItem.Allocated__c != null ? revreclineItem.Allocated__c +  (100 * (currentMilestone.Actual_Qty__c/lineItem.Quantity)) :  ((currentMilestone.Actual_Qty__c/lineItem.Quantity)) ;
                }
                //Amortize By = Percent
            } else {
                if(theSchedule.Date__c <= Date.Today()) {
                    if( currentMilestone.Actual_Percent__c != null ) 
                        recognizedTotalForREvRec += recognizableTotal * currentMilestone.Actual_Percent__c/100; 
                    else if( currentMilestone.Actual_Amount__c != null )
                        recognizedTotalForREvRec += currentMilestone.Actual_Amount__c;
                } 
                else {
                    if( currentMilestone.Actual_Percent__c != null ) 
                        deferredTotalForREvRec += recognizableTotal * currentMilestone.Actual_Percent__c/100; 
                    else if( currentMilestone.Actual_Amount__c != null )
                        deferredTotalForREvRec += currentMilestone.Actual_Amount__c;
                }
                
                if(LineItem.TotalPrice == 0.00) {
                    revreclineItem.Allocated__c = 0.00;
                } else {
                    if(currentMilestone.Actual_Percent__c != null)
                        revreclineItem.Allocated__c = revreclineItem.Allocated__c != null ? revreclineItem.Allocated__c + (currentMilestone.Actual_Percent__c) : (currentMilestone.Actual_Percent__c);
                }
            }
            
            //Populate fields on schedule
            theSchedule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
            theSchedule.Sequence__c = i + 1 ;                                                
            theSchedule.RecognizedRevTotal__c = monthlyAccumulated;  
            theSchedule.Rec_Total_Amt_Wei__c = (monthlyAccumulated * oppty.Probability) / 100;
            theSchedule.ResidualAmountTotal__c = revreclineItem.ResidualAmount__c;
            theSchedule.LineItemAmountTotal__c = lineItem.TotalPrice;
            theSchedule.LI_Amt_Total_Wei__c = (lineItem.TotalPrice * oppty.Probability) / 100;
            theSchedule.RecRevWei__c = (theSchedule.RecognizedRev__c * oppty.Probability) / 100;
            theSchedule.DefReWei__c = (theSchedule.DeferredRev__c * oppty.Probability) / 100;
            theSchedule.ForeRevWei__c = (theSchedule.ForecastedRev__c * oppty.Probability) / 100;
            
            if(lineItem.TotalPrice == 0)
                theSchedule.Recognized_Quantity__c = 0;
            else                    
                theSchedule.Recognized_Quantity__c = (((theSchedule.RecognizedRev__c * 100)/lineItem.TotalPrice) * lineItem.Quantity)/100;
            
            totalAMForAllMonths += theSchedule.RecognizedRev__c ;
            //Add schedule in list
            revenuSchedulesCopy.add(theSchedule);
        }
              
        if(LineItem.TotalPrice != (totalAMForAllMonths)) {          
            
            Decimal diffferAmount = Math.abs(LineItem.TotalPrice - totalAMForAllMonths);
            if(diffferAmount < 5) {
                if(divideBy != 'Prorate') {
                    
                    if(totalMilestones >= 1) {
                        revenuSchedulesCopy[totalMilestones - 1].RecognizedRev__c += diffferAmount;
                        revenuSchedulesCopy[totalMilestones - 1].DeferredRev__c -= diffferAmount;
                        recognizedTotalForREvRec += diffferAmount;
                        recognizableTotal -= diffferAmount;
                    }
                }else {
                    if(totalMilestones >= 2) {
                        revenuSchedulesCopy[totalMilestones - 2].RecognizedRev__c += diffferAmount;
                        revenuSchedulesCopy[totalMilestones - 2].DeferredRev__c -= diffferAmount;
                        recognizedTotalForREvRec += diffferAmount;
                        recognizableTotal -= diffferAmount;
                    }
                }
            }
        } 
        
        //Checking for null
        if(recognizedTotalForREvRec != null)
            revreclineItem.RecognizedRev__c = recognizedTotalForREvRec;
            
        //Populating RevRecLine item fields
        revreclineItem.DeferredRev__c = deferredTotalForREvRec;
        revreclineItem.DefReWei__c = (revreclineItem.DeferredRev__c * oppty.Probability) / 100;
        revreclineItem.RecRevWei__c = (revreclineItem.RecognizedRev__c * oppty.Probability) /100;
        revreclineItem.CalculatedAt__c = date.today();  
        revreclineItem.ForecastedRev__c = forecastedTotalForREvRec;
        revreclineItem.ForeRevWei__c = (revreclineItem.ForecastedRev__c * oppty.Probability) / 100;
        
        //Checking for null
        if(recognizableTotal != null)
            revreclineItem.TotalRev__c = recognizableTotal;
        revreclineItem.Total_Amt_Wei__c = (recognizableTotal * oppty.Probability) / 100;
                    
         //Code modified - (1/08/2016) - Check if multi currency enabled then do this
        if(isMultiCurrencyEnabled)
            revreclineItem.put('CurrencyIsoCode' , oppty.get('CurrencyIsoCode'));
        
        revenuSchedules.addAll(revenuSchedulesCopy);
        //Retun result
        return result;                  
    } 
    
    private string CalculateTotalPeriodForMonthlyAmortized(Date startDate, Date endDate, string devidedBy, RevRecProductRule__c overrideRule){
        boolean needProrate = (devidedBy != null &&  devidedBy  == 'Prorate'); 
        string result = '';
        Integer totalMonth = startDate.monthsBetween(endDate);
        if (startDate.day() <= endDate.day()) totalMonth++;

        Boolean startInCurrentMonth = true;
        if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                    // do nothing
        } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
            Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
            if (startDate.day() > settingDateInTheMonth) {
                if (!needProrate) totalMonth--; 
                startInCurrentMonth = false;
            }
            if (endDate.day() >  settingDateInTheMonth) 
                if (!needProrate) totalMonth++;         
        } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
            Date certainWeekCertainWeekdayForStartDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (startDate > certainWeekCertainWeekdayForStartDate) {
                if (!needProrate) totalMonth--; 
                startInCurrentMonth = false;
            }
            Date certainWeekCertainWeekdayForEndDate = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(endDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
            if (endDate >  certainWeekCertainWeekdayForEndDate) 
                if (!needProrate) totalMonth++;                 
        } 
        overrideRule.Total_Period__c = null;
        
        return result;                  
    }
    
    /** 
     *  @description        :   This method is used to calculate for the rule which is not overriden yet and create a copy of override rule from default rule.
     *
     *  @args               :   Opportunity oppty, OpportunityLineItem lineItem, 
     *                          RevRecRules__c theRule, RevRecProductRule__c overrideRule,
     *                          List<RevRecRuleMilestone__c> ruleMileStones, List<RevRecProductRuleMilestone__c> productMilestones,
     *                          Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName,
     *                          List<RevRecRuleCategory__c> revRecRuleCatg,
     *                          List<RevRecProductRuleCategory__c> revRecProductRuleCatg
     *
     *  @return             :   String msg -  This string is holding the error message if any.
    **/
    public String CalculateOverrideRuleFromRevRecRule(Opportunity oppty, OpportunityLineItem lineItem, Product2 pro,
        RevRecRules__c theRule, RevRecProductRule__c overrideRule, List<RevRecRuleMilestone__c> ruleMileStones, 
        List<RevRecProductRuleMilestone__c> productMilestones, Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName,
        List<RevRecRuleCategory__c> revRecRuleCatg, List<RevRecProductRuleCategory__c> revRecProductRuleCatg, Utility utl, Contract contr){
        
        if(theRule == null)
            theRule = new RevRecRules__c();
            
        //Variables 
        Double totalRev = lineItem.TotalPrice;
        Double residualTotal = 0;
        Double recognizedTotal = 0;
        Double recognizableTotal = 0; 
        Double residualWeightedTotal = 0;
        Double recognizedWeightedTotal = 0;
        Double recognizableWeightedTotal = 0;
        
        //Residual Amount
        Double residualAmount = (theRule.Residual_Amount__c == null) ? 0 : theRule.Residual_Amount__c ;
        
        if (theRule.Residual_Amount_Type__c == 'Percent') 
            residualTotal = (totalRev * residualAmount)/100.0;
        else 
            residualTotal = residualAmount;
        
        if(totalRev != null)
            recognizableTotal = totalRev;
        
        if(residualTotal != null)
            recognizableTotal -= residualTotal;
            
        String msg = '';
        boolean shouldContinue = true;
         
        if (theRule == null && defaultRule != null) {
            theRule = defaultRule;
            ruleMileStones = defaultRule.RevRecRuleMilestones__r;
        }
       
        if (theRule == null)
            return 'No Rule is assigned to the product, and no default rule defined.';
        
        if (overrideRule == null)
            overrideRule = new RevRecProductRule__c();

        if (ruleMileStones == null)  
            ruleMileStones =  new List<RevRecRuleMilestone__c> ();      
        
        // get the start date and end date
        String RevRecStartDateField = theRule.Revenue_Recognition_Start_Date__c;
        String RevRecEndDateField = theRule.Revenue_Recognition_End_Date__c;
        Date startDate = null;
        Date endDate = null;
        
        if (theRule.Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_MILESTONE) {  
            
             if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_OPPORTUNITY)){
                if(RevRecStartDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                    string fieldName = RevRecStartDateField.subString(20, RevRecStartDateField.length()); 
                    startDate = (Date)lineItem.get(fieldName);
                }
                else {
                    String fieldName = RevRecStartDateField.subString(12, RevRecStartDateField.length()); 
                    startDate = (Date)oppty.get(fieldName);
                }
            } else if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                    string fieldName = RevRecStartDateField.subString(8, RevRecStartDateField.length());
                    startDate = (Date)pro.get(fieldName);
            } else if (RevRecStartDateField != null && RevRecStartDateField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                    string fieldName = RevRecStartDateField.subString(9, RevRecStartDateField.length());
                    if(contr != null) 
                        startDate = (Date)contr.get(fieldName);
            } 

            if (theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION)
                endDate = startDate;
            else {
                if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_OPPORTUNITY)){
                    if(RevRecEndDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        
                        string fieldName = RevRecEndDateField.subString(20, RevRecEndDateField.length()); 
                        endDate = (Date)lineItem.get(fieldName);
                    } else {
                        string fieldName = RevRecEndDateField.subString(12, RevRecEndDateField.length());
                        endDate = (Date)oppty.get(fieldName);
                    }
                } else if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        string fieldName = RevRecEndDateField.subString(8, RevRecEndDateField.length());
                        endDate = (Date)pro.get(fieldName);
                } else if (RevRecEndDateField != null && RevRecEndDateField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                        string fieldName = RevRecEndDateField.subString(9, RevRecEndDateField.length());
                        if(contr!= null)
                            endDate = (Date)contr.get(fieldName);
                }  
            }   
        }
        
        //Temp list of milestones
        List<RevRecRuleMilestone__c> listMilesTemp = new  List<RevRecRuleMilestone__c>();
        
         // Code added - 04/05/2015 - As per Milestone Rule Requirements 
        //Start Amortized Milestone
        if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
           
            //Checking for list size
            if(ruleMileStones.size() > 0) {
                
                //Set milestone date to null
                Date mileStoneDate = null;
                
                //Loop through Milestones
                for(RevRecRuleMilestone__c  item : ruleMileStones) {
                    
                    //get the start date and end date    
                    String RevRecMileStoneDateSourceField = item.Milestone_Date_Source__c;
                        
                    //Checking if Date source is produuct / Opportunity /  Manual 
                    if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY)){
                        if(RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                            string fieldName = RevRecMileStoneDateSourceField.subString(20, RevRecMileStoneDateSourceField.length()); 
                            mileStoneDate = (Date)lineItem.get(fieldName);
                        }
                        else {
                            string fieldName = RevRecMileStoneDateSourceField.subString(12, RevRecMileStoneDateSourceField.length()); 
                            mileStoneDate = (Date)Oppty.get(fieldName);
                        }
                    } else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        string fieldName = RevRecMileStoneDateSourceField.subString(8, RevRecMileStoneDateSourceField.length());
                        mileStoneDate = (Date)pro.get(fieldName);
                    } else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                        string fieldName = RevRecMileStoneDateSourceField.subString(9, RevRecMileStoneDateSourceField.length());
                        if(contr != null)
                            mileStoneDate = (Date)contr.get(fieldName);
                    }
                    else 
                        mileStoneDate = null;
                    
                    //Code added - As per RevView new requirement - Milestone
                    if(theSetting.Is_Closed_Date_Validation__c)  {
                        if(mileStoneDate != null && oppty.CloseDate > mileStoneDate ) 
                            msg = constants.ERROR_MESSAGE_BASED_ON_DATES;
                    }
                    
                    //Checking if Date source is produuct / Opportunity /   Manual  
                    if ((RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) 
                                        || RevRecMileStoneDateSourceField != null 
                                        && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY_COLON)) {
                   
                        //Getting field label from field Api name
                        if(allDates.containsKey(RevRecMileStoneDateSourceField))
                             milestoneDateSource = allDates.get(RevRecMileStoneDateSourceField);
                   } else 
                        milestoneDateSource = constants.MILESTONE_DATE_MANUAL;
                    
                    //Set milestone date label
                    item.Milestone_Date_Source_Label__c = milestoneDateSource;
                    
                    //Set milestone date from date variable
                    item.Milestone_Date__c = mileStoneDate;
                    listMilesTemp.add(item);
                }
            } 
            ruleMileStones = listMilesTemp;
        }         
        
        // Code added - 11/01/2014 - As per Amortized Milestone Rule Requirements 
        //Start Amortized Milestone
        if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
           
           //Calling method to calculate start and end date
           AmortizeMileStartEndDate wrp  = utilHelper.startEndDateForAMRule(startDate, endDate, oppty, lineItem, pro, RevRecEndDateField, RevRecStartDateField, contr);
           startDate = wrp.startDate;
           endDate = wrp.endDate;
                        
            //Checking for conditions if start date or end date is null then show an error msg on page 
            if (startDate == null || endDate == null)
                msg = 'Revenue allocation/distribution cannot be calculated because some revenue dates (Start, End, etc.) are missing';        
            
            //Checking for Opportunity close date is greater than Dates
            if(theSetting.Is_Closed_Date_Validation__c)  {
                if(oppty.CloseDate > startDate ) 
                    msg = constants.ERROR_MESSAGE_BASED_ON_DATES;
                else if(oppty.CloseDate > endDate)
                    msg = constants.ERROR_MESSAGE_BASED_ON_DATES;
            }
            
            //Checking if no any date field is null
            //Creating Milestone: craeting according to start and end date
             if(startDate != null && endDate != null) {
                
                Double initial = 0;
                Double initialAmount = (theRule.initial_amount__c == null) ? 0 : theRule.initial_amount__c;
                
                if (theRule.initial_amount_type__c == 'percent') 
                    initial = recognizableTotal * initialAmount/100.0;
                else
                    initial = initialAmount;
                                 
                //List of milestones
                List<RevRecProductRuleMilestone__c> listMileStone = new List<RevRecProductRuleMilestone__c>();
                
                //Set to hold the milestone name
                Set<String> setMilstoneName = new Set<String>();
                
                //Fetch all the milstone from system related to this rule
                for(RevRecRuleMilestone__c allMileStonerelatedToRule : ruleMileStones) 
                    setMilstoneName.add(allMileStonerelatedToRule.Name);
            
                //Variables to hold the month values of start date and end date
                Integer startDateMonth = startDate.Month();
                Integer startDateYear = startDate.Year();
                Integer endDateMonth = endDate.Month();
                Integer endDateYear = endDate.Year();
                Date currentDate = Date.Today();
                Integer noOfDaysInCurrentMonth = Date.daysInMonth(currentDate.year(), currentDate.month());
                Date amortCurrentDate = Date.newInstance(currentDate.Year(), currentDate.Month(), currentDate.day());
                Integer totalMonths = startDate.MonthsBetween(endDate);
                Date tempDate = startDate.addMonths(totalMonths);
                Date lastDayOfMonth;
                Integer numberOfDays;
                Integer sequence  = 0;
                
                //Decimal to hold the amount for per month
                Decimal amountPerMonth = 0.00;
                Decimal quantityPerMonth = 0.00 ;
                
                //Checking for total months
                if(tempDate.daysBetween(endDate) >= 0) 
                    totalMonths = totalMonths+1;
        
                //Checking for 0
                if(totalMonths == 0)
                    totalMonths = totalMonths + 1;
                
                //Check for amortized by: 
                //-------------- Amortize by -> milestone type
                if(theRule.Milestone_Type__c.equalsIgnoreCase(Constants.PRODUCT_RULE_AMORTIZED_BY_AMOUNT)) {
                    amountPerMonth = (lineItem.TotalPrice/(totalMonths)).setScale(2);
                    if(lineItem.TotalPrice > 0)
                        quantityPerMonth = (amountPerMonth * lineItem.Quantity /lineItem.TotalPrice);
                    else
                        quantityPerMonth = 0.00;
                }
        
                //Total Amount actual
                Decimal totalAmountActual = amountPerMonth * (totalMonths);
                Decimal amountDiff = (lineItem.TotalPrice - totalAmountActual); 
                Decimal lastMonthAmt = amountPerMonth + amountDiff;
                
                //Month Difference between 
                Boolean inCurrentMonth = IsInCurrentMonthForBlended(startDate);
                Date transDate = getTransDateForBlended(startDate, inCurrentMonth);
                Integer transDay  = transDate.day(); 
                numberOfDays = transDay;
                Date amortStartDate = Date.newInstance(startDateYear, startDateMonth, numberOfDays);
            
                if(overrideRule.Milestone_Type__c == Constants.PRODUCT_RULE_AMORTIZED_BY_QUANTITY) {
                    quantityPerMonth = lineItem.Quantity/(totalMonths);
                    amountPerMonth = (lineItem.TotalPrice/(totalMonths)).setScale(2);
                }
                
                if (theRule.Period__c == 'Monthly') {
                    
                    Integer totalPeriods = startDate.monthsBetween(endDate) + 1;
                  
                    Integer offset = 0;
                    Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                    if (theRule.Offset_Period__c != null) {
                        if(theRule.offset_type__c == 'Start') {
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = true;
                        } else if (theRule.offset_type__c == 'Period'){
                            offset = Integer.valueOf(theRule.Offset_Period__c);
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
               
                    //need put logic for the start date and last of schedule before start data, they could fall into the same month
                    inCurrentMonth = IsInCurrentMonth(startDate);
                    Date transDateForStarDate = utilHelper.GetTransDate(startDate, inCurrentMonth, theSetting);
                    
                    boolean needProrate = (theRule.Divide_By__c != null &&  theRule.Divide_By__c  == 'Prorate');
            
                    Decimal actualAmount = 0;
                    Integer totalPeriod = 0;
                    Integer totalMonth = 0;
                    
                    //Checking for End date
                    if(endDate != null) {           
                        
                        totalPeriod = startDate.monthsBetween(endDate) + 1 ;
                        totalMonth = RevRecHelper.TotalMonthDifference(startDate, endDate);
                        if (totalMonth < 1) 
                            msg = 'Start Date and end Date should not be null for Amortize Milestone Rule and End Date must be greater than start date';
                        else {
                        
                            //the decision is made that if amortize by period on 1/15/2014 to 1/14/2015 is 12 period, do not need consider prorate 
                            if (theRule.Divide_By__c != null &&  theRule.Divide_By__c  == 'Period')
                                totalPeriod = totalMonth;
                            
                            Integer totalDays = 0;
                            if(endDate != null)
                                totalDays = startDate.daysBetween(endDate) + 1;
                                
                            Integer totalDaysInFirstPeriod = startDate.daysBetween(startDate.addMonths(1).toStartOfMonth());
                            Integer totalDaysInLastPeriod= (endDate.toStartOfMonth()).daysBetween(endDate) + 1;
                            double dailyRecognizable= (lineItem.TotalPrice-initial)/totalDays;
                            
                            double recognizableForEachPeriod = (recognizableTotal-initial)/totalPeriod;
                            double recognizableForEachMonth = (recognizableTotal-initial)/totalMonth;
                             
                            Double firstMonthRecognizableByDailyRatio = 0.00;
                            Double lastMonthRecognizableByDailyRatio = 0.00;
                            
                            if(theRule.Period_or_Exact_Days__c == 'Percentage' && needProrate) {
                                
                                //Variable to hold monthly recognizable amount for percentized calculation
                                Double monthlyRecognizableAmount = recognizableTotal/totalMonth;
                                
                                if(theRule.Start_Percentage__c != null)
                                    firstMonthRecognizableByDailyRatio = monthlyRecognizableAmount * (theRule.Start_Percentage__c /100);
                                    
                                if(theRule.End_Percentage__c != null)
                                    lastMonthRecognizableByDailyRatio = monthlyRecognizableAmount * (theRule.End_Percentage__c /100);                             
                            }else {
                                
                                firstMonthRecognizableByDailyRatio = dailyRecognizable * totalDaysInFirstPeriod;
                                lastMonthRecognizableByDailyRatio = dailyRecognizable * totalDaysInLastPeriod; 
                            }
                            
                            Boolean startInCurrentMonth = true;
                            if (theRule.Divide_By__c != null &&  theRule.Divide_By__c  == 'Period') {
                                //the decision is made that if amortize by period on 1/15/2014 to 1/14/2015 is 12 period, do not need consider prorate 
                            } else if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                                        // do nothing
                            } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
                                Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
                                if (startDate.day() > settingDateInTheMonth) 
                                    startInCurrentMonth = false;
                            } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
                                Date certainWeekCertainWeekdayForStartDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(startDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                                if (startDate > certainWeekCertainWeekdayForStartDate)
                                    startInCurrentMonth = false;
                            }
                            Date initialDate = startDate;
                            double monthlyAccumulated = 0;
                            
                            for (Integer j=0; j < totalPeriod; j++) {               
                                
                                //Variables to hold the month values of start date and end date
                                startDateMonth = startDate.addMonths(j).Month();
                                startDateYear = startDate.addMonths(j).Year();
                                
                                if(theSetting.Time_of_Month_Selection_Types_tr__c == '1')
                                    numberOfDays = Date.daysInMonth(startDateYear, startDateMonth);
                                                                    
                                lastDayOfMonth = Date.newInstance(startDateYear, startDateMonth, numberOfDays);
                                
                                //calculate each period
                                Integer totalDaysInMonth = Date.daysInMonth(startDateYear, startDateMonth);
                                
                                if (j== 0) {
                                   
                                    if (needProrate) {
                                        if (theRule.Period_or_Exact_Days__c == 'exact')
                                            actualAmount = recognizableForEachMonth * totalDaysInFirstPeriod/totalDaysInMonth;
                                        else 
                                            actualAmount = firstMonthRecognizableByDailyRatio;                 
                                    } else {
                                        if (theRule.Period_or_Exact_Days__c == 'period')
                                            actualAmount = recognizableForEachPeriod;
                                        else 
                                            actualAmount = dailyRecognizable * totalDaysInFirstPeriod;                 
                                    } 
                                }   
                                else if (j == totalPeriod -1 ){
                                    if (needProrate) {
                                        if (theRule.Period_or_Exact_Days__c == 'exact')
                                            actualAmount = recognizableForEachMonth * totalDaysInLastPeriod/totalDaysInMonth;
                                        else
                                            actualAmount = lastMonthRecognizableByDailyRatio;  
                                    } else {
                                        
                                        if (theRule.Period_or_Exact_Days__c == 'period')
                                            actualAmount = recognizableForEachPeriod;
                                        else 
                                            actualAmount = dailyRecognizable * (startDate.daysBetween(startDate.addMonths(1).toStartOfMonth())); 
                                    }
                                }
                                else { 
                                    
                                    if (needProrate) {
                                        if (theRule.Period_or_Exact_Days__c == 'exact') 
                                            actualAmount = dailyRecognizable * totalDaysInMonth;
                                        else 
                                            actualAmount = (recognizableTotal-initial - firstMonthRecognizableByDailyRatio - lastMonthRecognizableByDailyRatio)/(totalPeriod - 2);
                                    } else {
                                        if (theRule.Period_or_Exact_Days__c == 'period')
                                            actualAmount = recognizableForEachPeriod;
                                        else 
                                            actualAmount = totalDaysInMonth * dailyRecognizable;                    
                                    }
                                }
                                
                                actualAmount = actualAmount.setScale(2);
                                if((!setMilstoneName.contains(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear)))) {
                                                            mapRevRecMileStoneWithName.put(Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear), 
                                                                                           new RevRecRuleMilestone__c(Name = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                           Amount__c = actualAmount, Qty__c = quantityPerMonth, 
                                                                                           Actual_Amount__c = actualAmount,Actual_Qty__c = quantityPerMonth,
                                                                                           Projected_Amount__c = actualAmount,Projected_Qty__c = quantityPerMonth,                                                                                                                                                                                                                                                                                                                                                                                               
                                                                                           Milestone_Name__c = Constants.convertNumberToMonthText(startDateMonth)+' - '+String.valueOf(startDateYear),
                                                                                           Milestone_Sequence__c = j+1, Milestone_Date_Source_Label__c = 'MANUAL',
                                                                                           RevRecRule__c = theRule.Id, Milestone_Date_Source__c = 'MANUAL',
                                                                                           MileStone_Date__c = lastDayOfMonth));
                                }
                            }
                        }
                    }
                }
            }
        }
            
        /***** Code added - 06/15/2015 - As per Blended Revenue Recognition requirement ******/
        //Temp list of recrecRuleCategory
        List<RevRecRuleCategory__c> tempListCat = new List<RevRecRuleCategory__c>();
                
        //Start Blended revenue calcualtion
        if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {

            if(revRecRuleCatg == null)
                revRecRuleCatg = new List<RevRecRuleCategory__c>();
                
            //Checking for list size   
            if(revRecRuleCatg != null && revRecRuleCatg.size() > 0) {
                
                //Set  dates to null default
                Date actualStartDate = null;
                Date actualEndDate = null;
                
                //Loop through Milestones   
                for(RevRecRuleCategory__c  item : revRecRuleCatg) {
                    //get the start date and end date    
                    String RevRecStartDate = item.Category_Start_Date__c;
                    String RevRecEndDate = item.Category_End_Date__c;
                    
                    //Checking if start date not null and Conatins Opportunity , product or Blank
                    if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_OPPORTUNITY)){
                        if(RevRecStartDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                            string fieldName = RevRecStartDate.subString(20, RevRecStartDate.length()); 
                            actualStartDate = (Date)lineItem.get(fieldName);    
                        }
                        else {
                            string fieldName = RevRecStartDate.subString(12, RevRecStartDate.length()); 
                            actualStartDate = (Date)Oppty.get(fieldName);
                        }
                    } else if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        string fieldName = RevRecStartDate.subString(8, RevRecStartDate.length());
                        actualStartDate = (Date)pro.get(fieldName);
                    } else if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_CONTRACT_COLON)) {
                        string fieldName = RevRecStartDate.subString(9, RevRecStartDate.length());
                        if(contr != null)
                            actualStartDate = (Date)contr.get(fieldName);
                    } else
                        actualStartDate = null;
                    
                    //Checking if end date not null and Conatins Opportunity , product or Blank
                    if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_OPPORTUNITY)){
                        if(RevRecEndDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                            string fieldName = RevRecEndDate.subString(20, RevRecEndDate.length()); 
                            actualEndDate = (Date)lineItem.get(fieldName);
                        }
                        else {
                            string fieldName = RevRecEndDate.subString(12, RevRecEndDate.length()); 
                            actualEndDate = (Date)Oppty.get(fieldName);
                        }
                    } else if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        string fieldName = RevRecEndDate.subString(8, RevRecEndDate.length());
                        actualEndDate = (Date)pro.get(fieldName);
                    } else if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_CONTRACT_COLON)) {
                        string fieldName = RevRecEndDate.subString(9, RevRecEndDate.length());
                        if(contr != null)
                            actualEndDate = (Date)contr.get(fieldName);
                    } else
                        actualEndDate = null;
                  
                    //Set Date from variables
                    item.Actual_Start_Date__c =  actualStartDate;
                    item.Actual_End_Date__c = actualEndDate;
                    tempListCat.add(item);
                }
            }
            revRecRuleCatg = tempListCat;
        }         
        
        //Field added in Query - 01/19/2015 - As per Milestone Date Automation requirement
        //Query through all milstone relayted to rule and populate map
        //Add Milestone_Date_Source_Label__c, Milestone_Date_Source__c in query
        List<RevRecRuleMilestone__c> allMileStones = ruleMileStones;
        
        ///Checking for milestone size 
        if(allMileStones.size() > 0) {                
            for(RevRecRuleMilestone__c mlS: allMileStones) 
                mapRevRecMileStoneWithName.put(mlS.Milestone_Name__c, mlS);
        }
        
        //End Amortize milestone calculation
        overrideRule.Residual_Amount__c = theRule.Residual_Amount__c;
        overrideRule.Residual_Amount_Type__c = theRule.Residual_Amount_Type__c;
        overrideRule.initial_amount__c = theRule.initial_amount__c;
        overrideRule.initial_amount_type__c = theRule.initial_amount_type__c;
        overrideRule.Recognition_Type__c = theRule.Recognition_Type__c;
        overrideRule.offset_type__c  = theRule.offset_type__c;
        overrideRule.Offset_Period__c  = theRule.Offset_Period__c;
        overrideRule.Divide_By__c  = theRule.Divide_By__c;
        overrideRule.offset_type__c  = theRule.offset_type__c;
        overrideRule.name  = '[overridden] ' + theRule.name ;
        overrideRule.Period_or_Exact_Days__c = theRule.Period_or_Exact_Days__c;
        overrideRule.Milestone_Type__c = theRule.Milestone_Type__c;
        overrideRule.Start_Percentage__c = theRule.Start_Percentage__c;
        overrideRule.End_Percentage__c = theRule.End_Percentage__c;
        overrideRule.Period_or_Exact_Days__c = theRule.Period_or_Exact_Days__c;
        overrideRule.Is_Split_Categories__c = theRule.Is_Split_Categories__c;
        overrideRule.Divide_By__c = theRule.Divide_By__c;
        if(theRule.Enable_Manual_Forecast__c)
            overrideRule.Enable_Manual_Forecast__c = true;
        else
            overrideRule.Enable_Manual_Forecast__c = false;
        overrideRule.Forecast_With_Zero_Value__c = theRule.Forecast_With_Zero_Value__c;
        overrideRule.Period__c = theRule.Period__c;
        overrideRule.Revenue_Recognition_End_Date__c = theRule.Revenue_Recognition_End_Date__c; 
        overrideRule.Revenue_Recognition_Start_Date__c = theRule.Revenue_Recognition_Start_Date__c;
        
        //Added on 03/14/2018 for Issue #1- Wrong warning when rule is not assigned
        if(theRule.Recognition_Type__c != null && theRule.Recognition_Type__c != '') {
            if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                overrideRule.Start_Date__c = startDate;
            } else if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                for(RevRecRuleMilestone__c item : ruleMileStones) {
                    RevRecProductRuleMilestone__c productMilestone = new RevRecProductRuleMilestone__c(Milestone_Name__c = item.Milestone_Name__c, 
                        Milestone_Sequence__c= item.Milestone_Sequence__c, Percent__c= item.Percent__c);
                    //Code modified - 03/11/2015 - As per final set of bug fixes
                    //Code modified - 01/30/2015 - Set 2 decimal place
                    if(theRule.Milestone_Type__c == 'percent' && item.Actual_Percent__c != null) {
                        productMilestone.Actual_Amount__c = (lineItem.TotalPrice * item.Actual_Percent__c / 100).setScale(2) ;  //Added on 03/06/2018
                        
                        if(item.Actual_Qty__c == null){
                            productMilestone.Actual_Qty__c = (lineItem.Quantity * item.Actual_Percent__c / 100).setScale(2) ;
                        }
                        else {  
                            productMilestone.Actual_Qty__c = item.Actual_Qty__c;
                        }
                        
                        productMilestone.Actual_Percent__c = item.Actual_Percent__c;
                    }else if(theRule.Milestone_Type__c == 'amount' && item.Actual_Amount__c != null) {
                        
                        if(item.Actual_Percent__c == null )  {
                            
                            if(lineItem.TotalPrice > 0 )
                                productMilestone.Actual_Percent__c = ((item.Actual_Amount__c / lineItem.TotalPrice)*100).setScale(2) ;
                            else
                                productMilestone.Actual_Percent__c = 0.00;  
                        }
                        else
                            productMilestone.Actual_Percent__c = item.Actual_Percent__c.setScale(2) ;
                        
                        if(item.Actual_Qty__c == null)
                            productMilestone.Actual_Qty__c = (lineItem.Quantity * productMilestone.Actual_Percent__c / 100).setScale(2) ;
                        else
                            productMilestone.Actual_Qty__c = item.Actual_Qty__c;
                        
                        productMilestone.Actual_Amount__c = item.Actual_Amount__c;
                        
                    }else if(theRule.Milestone_Type__c == 'qty' && item.Actual_Qty__c != null) {
                        
                        if(item.Actual_Qty__c != null)
                            productMilestone.Actual_Amount__c = (lineItem.UnitPrice * item.Actual_Qty__c).setScale(2) ;
                        
                        if(item.Actual_Percent__c == null)
                            if(lineItem.TotalPrice == 0)
                                productMilestone.Actual_Percent__c = 0;
                            else    
                                productMilestone.Actual_Percent__c = ((((lineItem.UnitPrice * item.Actual_Qty__c) / lineItem.TotalPrice))*100).setScale(2) ;
                        else
                            productMilestone.Actual_Percent__c = item.Actual_Percent__c.setScale(2);
                        productMilestone.Actual_Qty__c = item.Actual_Qty__c;
                    }
                    
                    //Code is added for Projected calculation on 11/14/2017
                    if(theRule.Milestone_Type__c == 'percent' && item.Projected_Percent__c != null) {
                        productMilestone.Projected_Amount__c = (lineItem.TotalPrice * item.Projected_Percent__c / 100).setScale(2) ;
                        if(item.Projected_Qty__c == null)
                            productMilestone.Projected_Qty__c = (lineItem.Quantity * item.Projected_Percent__c / 100).setScale(2) ;
                        else
                            productMilestone.Projected_Qty__c = item.Projected_Qty__c;
                        
                        productMilestone.Projected_Percent__c = item.Projected_Percent__c;
                    }else if(theRule.Milestone_Type__c == 'amount' && item.Projected_Amount__c != null) {
                        
                        if(item.Projected_Percent__c == null )  {
                            
                            if(lineItem.TotalPrice > 0 )
                                productMilestone.Projected_Percent__c = ((item.Projected_Amount__c / lineItem.TotalPrice)*100).setScale(2) ;
                            else
                                productMilestone.Projected_Percent__c = 0.00;  
                        }
                        else 
                            productMilestone.Projected_Percent__c = item.Projected_Percent__c.setScale(2) ;
                        
                        if(item.Projected_Qty__c == null)
                            productMilestone.Projected_Qty__c = (lineItem.Quantity * productMilestone.Projected_Percent__c / 100).setScale(2) ;
                        else
                            productMilestone.Projected_Qty__c = item.Projected_Qty__c;
                       
                        productMilestone.Projected_Amount__c = item.Projected_Amount__c;
                        
                    }else if(theRule.Milestone_Type__c == 'qty' && item.Projected_Qty__c != null) {
                        
                        if(item.Projected_Qty__c != null)
                            productMilestone.Projected_Amount__c = (lineItem.UnitPrice * item.Projected_Qty__c).setScale(2) ;
                        
                        if(item.Projected_Percent__c == null)
                            if(lineItem.TotalPrice == 0)
                                productMilestone.Projected_Percent__c = 0;
                            else    
                                productMilestone.Projected_Percent__c = ((((lineItem.UnitPrice * item.Projected_Qty__c) / lineItem.TotalPrice))*100).setScale(2) ;
                        else
                            productMilestone.Projected_Percent__c = item.Projected_Percent__c.setScale(2) ;
                        
                        productMilestone.Projected_Qty__c = item.Projected_Qty__c;
                    }
                    
                    //Code added - 01/19/2015 - As per Milestone Date Automation requirment
                    productMilestone.Milestone_Date_Source__c = item.Milestone_Date_Source__c;
                    productMilestone.MileStone_Date__c = item.milestone_Date__c;
                    productMilestone.Milestone_Date_Source_Label__c = item.Milestone_Date_Source_Label__c;

                    //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                    //If true the do this 
                    if(isMultiCurrencyEnabled) {
                        
                        if(productMilestone.Actual_Amount__c != null) {
                            productMilestone.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), productMilestone.Actual_Amount__c)).replace('<br/>', '');
                            productMilestone.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Actual_Amount__c));
                        } else {
                            productMilestone.Converted_Actual_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                            productMilestone.Cor_Act_Amt__c = 0.00;
                        }
                    }       
                    productMilestones.add(productMilestone);
                } 
            }
            
            // Code added - 11/01/2014 - As per Amortized Milestone Rule Requirements 
            else if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                //Map to holold milestones correspons=ding to sequence
                Map<Integer, RevRecProductRuleMilestone__c> mapMilestoneWithSequence = new Map<Integer, RevRecProductRuleMilestone__c>();
                
                if(startDate != null)
                    overrideRule.Start_Date__c = startDate;
                if(endDate != null)
                    overrideRule.End_Date__c = endDate;
                
                if(mapRevRecMileStoneWithName.values().size() > 0 ){
                    
                    for(RevRecRuleMilestone__c item : mapRevRecMileStoneWithName.values()) {
                        
                        RevRecProductRuleMilestone__c productMilestone = new RevRecProductRuleMilestone__c(Name = item.Name, Milestone_Name__c = item.Milestone_Name__c, Milestone_Sequence__c= item.Milestone_Sequence__c);
                        productMilestone.Amount__c =  (item.Amount__c) != null ? (item.Amount__c).setScale(2) : 0.00;
                        productMilestone.Qty__c =  (item.Qty__c) != null ? (item.Qty__c) : 0.00 ;
                        productMilestone.Percent__c =  (item.Percent__c) != null ? (item.Percent__c) : 0.00 ;
                        productMilestone.Actual_Amount__c =  (item.Actual_Amount__c) != null ? (item.Actual_Amount__c).setScale(2) : 0.00;
                        productMilestone.Actual_Qty__c =  (item.Actual_Qty__c) != null ? (item.Actual_Qty__c) : 0.00 ;
                        productMilestone.Actual_Percent__c =  (item.Actual_Percent__c) != null ? (item.Actual_Percent__c) : 0.00 ;
                        productMilestone.Projected_Amount__c =  (item.Projected_Amount__c) != null ? (item.Projected_Amount__c).setScale(2) : 0.00;
                        productMilestone.Projected_Qty__c =  (item.Projected_Qty__c) != null ? (item.Projected_Qty__c) : 0.00 ;
                        productMilestone.Projected_Percent__c =  (item.Projected_Percent__c) != null ? (item.Projected_Percent__c) : 0.00 ;
                        productMilestone.MileStone_Date__c = (item.MileStone_Date__c) != null ?  (item.MileStone_Date__c) : null;
                        
                        //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                        //If true the do this 
                        if(isMultiCurrencyEnabled) {
                            
                            Decimal prob = oppty.Probability / 100;
                            if(productMilestone.Amount__c != null) {
                                productMilestone.Converted_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), productMilestone.Amount__c)).replace('<br/>', '');    
                                productMilestone.Cor_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Amount__c));    
                                productMilestone.Cor_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Amount__c)) * prob;
                            } else {
                                productMilestone.Converted_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                                productMilestone.Cor_Amt__c = 0.00;
                                productMilestone.Cor_Amt_Wei__c = 0.00;
                            }
                            if(productMilestone.Actual_Amount__c != null) {
                                productMilestone.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), productMilestone.Actual_Amount__c)).replace('<br/>', '');
                                productMilestone.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Actual_Amount__c));    
                                productMilestone.Cor_Act_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Actual_Amount__c)) * prob;
                            } else {
                                productMilestone.Converted_Actual_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                                productMilestone.Cor_Act_Amt__c = 0.00;
                                productMilestone.Cor_Act_Amt_Wei__c = 0.00;
                            }
                            if(productMilestone.Projected_Amount__c != null) {
                                productMilestone.Converted_Sales_Manual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(Oppty.get('CurrencyIsoCode')), String.valueOf(Oppty.get('REVvue_CurrencyType__c')), productMilestone.Projected_Amount__c)).replace('<br/>', '');
                                productMilestone.Cor_Prj_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Projected_Amount__c));    
                                productMilestone.Cor_Prj_Amt_Wei__c = (utl.corporateCurrencyCalculation(String.valueOf(Oppty.get('CurrencyIsoCode')), productMilestone.Projected_Amount__c)) * prob;
                            } else {
                                productMilestone.Converted_Sales_Manual_Amount__c = Oppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + Oppty.get('CurrencyIsoCode') + ' 0.00 )';
                                productMilestone.Cor_Prj_Amt__c = 0.00;
                                productMilestone.Cor_Prj_Amt_Wei__c = 0.00;
                            }
                        }
                        
                        //popuulate map to get milestones according to milestone Sequence
                        mapMilestoneWithSequence.put(Integer.valueOf(productMilestone.Milestone_Sequence__c), productMilestone);
                    }
                    
                    //List of Sequence
                    List<Integer> listSequences = new List<Integer>();
                    listSequences.addAll(mapMilestoneWithSequence.keySet());
                    listSequences.sort();
                    
                    //Clear wrapper class   
                    productMilestones.clear();
                    
                    //Loop over sequences
                    for(Integer seq  : listSequences) 
                        productMilestones.add(mapMilestoneWithSequence.get(seq));
                }
            } 
            
            //Code added - 03/16/2015 - As per Blended Revenue Recognition requirement
            else if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
                
                //Checkling for Null
                if(revRecRuleCatg.size() > 0) {

                    //Variables to hold recognized and deferred amount
                    Decimal recognizedAmount ;
                    Decimal deferredAmount;
                    Decimal actualDeferred;
                    Decimal actualCatDifference = 0.00;
                    Decimal outstandingBalance = lineItem.TotalPrice;
                    Boolean isCategorySplitted ;
                    isCategorySplitted = false;
 
                    //Loop thrrough the RevRecRuleCategory
                    for(RevRecRuleCategory__c revRecCategory : revRecRuleCatg) {
                        //Initilize variables
                        deferredAmount = 0.00;
                        recognizedAmount = 0.00;
                        actualDeferred = 0.00;
                        
                        //New instance of Product rule Categories
                        RevRecProductRuleCategory__c productCategory = new RevRecProductRuleCategory__c(Name = revRecCategory.Name, Line_Item__c = revRecCategory.Line_Item__c,
                                                                                                        Category_End_Date__c = revRecCategory.Category_End_Date__c,
                                                                                                        Category_Start_Date__c = revRecCategory.Category_Start_Date__c,
                                                                                                        Category_Type__c = revRecCategory.Category_Type__c,
                                                                                                        Recognition_Type__c = revRecCategory.Recognition_Type__c, 
                                                                                                        Sequence__c = revRecCategory.Sequence__c,
                                                                                                        Actual_End_Date__c = revRecCategory.Actual_End_Date__c,
                                                                                                        Actual_Start_Date__c = revRecCategory.Actual_Start_Date__c,
                                                                                                        Old_Split__c = revRecCategory.Is_Split__c != null ? revRecCategory.Is_Split__c :  false );    
                       
                        //Checking for NULL
                        if(revRecCategory.Amount__c != null)
                            productCategory.Amount__c = revRecCategory.Amount__c.setScale(2);
                        
                        //Checking for NULL
                        if(revRecCategory.Qty__c != null)
                            productCategory.Qty__c = revRecCategory.Qty__c; 
                        
                        //Checking for NULL
                        if(revRecCategory.Percent__c != null)
                            productCategory.Percent__c = revRecCategory.Percent__c;     
                        
                        //Checking for NULL
                        if(revRecCategory.Projected_Amount__c != null)
                            productCategory.Projected_Amount__c = revRecCategory.Projected_Amount__c.setScale(2);
                        
                        //Checking for NULL
                        if(revRecCategory.Projected_Qty__c != null)
                            productCategory.Projected_Qty__c = revRecCategory.Projected_Qty__c; 
                        
                        //Checking for NULL
                        if(revRecCategory.Projected_Percent__c != null)
                            productCategory.Projected_Percent__c = revRecCategory.Projected_Percent__c; 
                     
                        //Calling method to calculate recognized and deferred amount
                        wrapCalculation = calculateRecAndDeferredRevForBlended(productCategory, outstandingBalance, recognizedAmount, deferredAmount, lineitem, msg, revRecProductRuleCatg, null, actualDeferred, overrideRule);

                        recognizedAmount = wrapCalculation.recognizedAmount;
                        deferredAmount = wrapCalculation.deferredAmount;
                        outstandingBalance = wrapCalculation.outStandingBalance;
                        actualDeferred = wrapCalculation.actualDeferred;
                        actualCatDifference = wrapCalculation.actualCatDifference;
                        msg = wrapCalculation.msg;   
                        
                        //Set values in Product Category
                        productCategory.Recognized_Amount__c = recognizedAmount;
                        productCategory.Deferred_Amount__c = deferredAmount;
                        productCategory.Actual_Deferred__c = actualDeferred;
                        outstandingBalance = outstandingBalance - actualCatDifference;
                        
                        revRecProductRuleCatg.add(productCategory); 
                        
                        //Checking for the splitted category
                        if(overrideRule.Is_Split_Categories__c)
                            isCategorySplitted = true;
                        
                        //If category is splitted then put it into the map
                        if(isCategorySplitted) {
                            
                            String key = theRule.Id + '-' + lineitem.Id;
                            productCategory.Old_Splitted_Category__c = revRecCategory.RevRecRuleSplitCategory__c;
                            productCategory.Old_Ultimate_Category__c = revRecCategory.Ultimate_Parent__c;
                            productCategory.Old_Rule_Id__c = key;
                            productCategory.Line_Item_Id__c = lineitem.Id;
                            productCategory.Level__c = revRecCategory.Level__c;
                            
                            String Key1 = revRecCategory.Id + '_' + lineitem.Id;
                            mapOldRuleCategoryIdWithNewCatg.put(key1 , productCategory);
                            
                            if(!mapOldRuleIdWithNewOverrideRule.containsKey(key))
                                mapOldRuleIdWithNewOverrideRule.put(key , overrideRule);
                        }
                    } 
                }
            } 
            else { //amortized
                
                overrideRule.Start_Date__c = startDate;
                overrideRule.End_Date__c = endDate;
                overrideRule.Period__c = theRule.Period__c;
                //Checking for conditions if start date or end date is null then show an error msg on page 
                
                if(startDate == null || endDate == null) {
                    msg = Constants.START_END_DATE_ERROR_MESSAGE;
                } else if(startDate > endDate) {
                    msg = 'Start Date and end Date should not be null for Amortize Rule and End Date must be greater than start date';
                } else if (theRule.Period__c == 'Monthly') {
                    Integer offset = 0;
                    Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                    if (theRule.Offset_Period__c != null) {
                        if(theRule.offset_type__c == 'Start') {
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = true;
                        } else if (theRule.offset_type__c == 'Period'){
                            offset = Integer.valueOf(theRule.Offset_Period__c);
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
                    msg += CalculateTotalPeriodForMonthlyAmortized(startDate, endDate, theRule.Divide_By__c, overrideRule);
                } //period monthly
                else if (theRule.Period__c == 'Weekly'){
                    Integer offset = 0;
                    Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                    if (theRule.Offset_Period__c != null) {
                        if(theRule.offset_type__c == 'Start') {
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = true;
                        } else if (theRule.offset_type__c == 'Period'){
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = false;
                        }
                    }
                    if (offset > 0) {
                        If (IsOffsetStart && (startDate.addDays(offset * 7) < endDate)) {
                            startDate = startDate.addDays(offset * 7);      
                        } else if (!IsOffsetStart) {
                            startDate = startDate.addDays(offset * 7);
                            endDate = endDate.addDays(offset * 7);
                        }
                    }
                    
                    msg += utilHelper.CalculateTotalPeriodForWeeklyAmortized(startDate, endDate, overrideRule); 
                } //period weekly
                else if (theRule.Period__c == 'Yearly'){
                    Integer offset = 0;
                    Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                    if (theRule.Offset_Period__c != null) {
                        if(theRule.offset_type__c == 'Start') {
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = true;
                        } else if (theRule.offset_type__c == 'Period'){
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = false;
                        }
                    }
                    if (offset > 0) {
                        If (IsOffsetStart && (startDate.addYears(offset) < endDate)) {
                            startDate = startDate.addYears(offset);     
                        } else if (!IsOffsetStart) {
                            startDate = startDate.addYears(offset);
                            endDate = endDate.addYears(offset);
                        }
                    }
                    
                    msg += utilHelper.CalculateTotalPeriodForYearlyAmortized(startDate, endDate, overrideRule, theSetting); 
                } //period yearly
                else if (theRule.Period__c == 'Quarterly'){
                    Integer offset = 0;
                    Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                    if (theRule.Offset_Period__c != null) {
                        if(theRule.offset_type__c == 'Start') {
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = true;
                        } else if (theRule.offset_type__c == 'Period'){
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = false;
                        }
                    }
                    if (offset > 0) {
                        If (IsOffsetStart && (startDate.addMonths(offset*3) < endDate)) {
                            startDate = startDate.addMonths(offset*3);      
                        } else if (!IsOffsetStart) {
                            startDate = startDate.addMonths(offset*3);
                            endDate = endDate.addMonths(offset*3);
                        }
                    }
                    
                    msg += utilHelper.CalculateTotalPeriodForQuartlyAmortized(startDate, endDate, overrideRule,theSetting); 
                } //period Quarterly
                else if (theRule.Period__c == 'Daily'){
                    Integer offset = 0;
                    Boolean IsOffsetStart = true;  //default offset type is start, and if no offset, offset period is 0 
                    if (theRule.Offset_Period__c != null) {
                        if(theRule.offset_type__c == 'Start') {
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = true;
                        } else if (theRule.offset_type__c == 'Period'){
                            offset = Integer.valueOf(theRule.Offset_Period__c);
                            IsOffsetStart = false;
                        }
                    }
                    if (offset > 0) {
                        If (IsOffsetStart && (startDate.addDays(offset) < endDate)) {
                            startDate = startDate.addDays(offset);      
                        } else if (!IsOffsetStart) {
                            startDate = startDate.addDays(offset);
                            endDate = endDate.addDays(offset);
                        }
                    }
                    Integer totalDays = startDate.daysBetween(endDate) + 1; 
                    overrideRule.Total_Period__c = null;
                } //period daily
            } //end amortized 
            
            //Opportunity/Reports for Amortized Milestones Line item
            //Check if rule type is amortize milestone or milestone
            if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE || theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                //Check if override rule is not null and RROLI is stamp on line item
                if(overrideRule != null && lineItem.RevRecOpportunityLineItem__c != null) {                  
                    //Seeting flag rule is auto manual
                    overrideRule.Is_Default_Overriden__c = true; 
                    overrideRule.RevRecOpportunityLineItem__c = lineItem.RevRecOpportunityLineItem__c;
                    
                    if(theRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)
                        overrideRule.Milestone_Type__c = 'amount';
                    //By pass the trigger
                    Constants.IS_BY_PASS_TRIGGER = true; 
                    
                    //Inserting override rule 
                    if(msg.length() <=   0) 
                        overriddenRuleToBeInserted.add(overrideRule);
                }
            } 
        }
        return msg; 
    }
}