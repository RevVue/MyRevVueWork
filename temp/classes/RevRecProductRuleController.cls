public with sharing class RevRecProductRuleController {
    
    //Variables
    public String opportunityId{get;set;} 
    Opportunity theOppty ; 
    RevRecProductRule__c overrideRule; 
    public RevRecOpportunityLineItem__c revRecLineItem{get;set;}  
    public OpportunityLineItem lineItem{get;set;}
    public String changedRuleType {get;set;}
    public String startDateString {get;set;}
    public String endDateString {get;set;}
    public String startDateStringDefault {get;set;}
    public String endDateStringDefault {get;set;}
    public Boolean IsInitializZero;
    public Boolean IsLIAmountChanged;
    public Boolean editable {get; set;}
    public Boolean errVisibility {get;set;}
    public Boolean defaultOverridden {get;set;}
    public Boolean hideErrorOnSave; 
    //Flag to show adjust and pricing button
    public Boolean isShowAdjuctAndPricingButton{get;set;}
    private String lineItemId;  
    private String salesforceTheme;
    
    Utility utl;    
    RevRecUtilHelper utilHelper = new RevRecUtilHelper();
    public String milestoneDateSource;
    Map<String, String> allDates;     
    RevRecAppSetting__c theSetting;
    OpportunityLineItem oli = new OpportunityLineItem();
    Product2 product2 = new Product2();
    Contract contract = new Contract();
    
    public RevRecProductRule__c getRecord () {return overrideRule; }
    public void setRecord(RevRecProductRule__c value) {
        overrideRule = value;   
    }
    
    //Flags  
    boolean showAmortizeDetail = false;
    boolean showMilestoneDetail = false;
    
    //Code added - 02/03/2015 - Boolean to check date is not in future
    public boolean isRecognizedDate;
    
    //Code Added - 10/31/2014 - As per Amortized Milestone Rule Requirements
    boolean showAmortizeMilestoneDetail = false;
    boolean showValidateAMAgainstLI = true;
    public boolean getShowValidateAMAgainstLI() {return showValidateAMAgainstLI;}
    public boolean getShowAmortizeMilestoneDetail() {return showAmortizeMilestoneDetail;}
    public string selectedAm {get;set;}
    public string selectedAmForSM {get;set;}
    public string selectedAmType {get;set;}
    public List<RevRecRuleMilestone__c> RevRecRulesMilestones{get;set;}
    Set<Id> setMilesIdToBeDeleted;
    public String errorMsg {get; set;}
    
    //Code Added - 06/13/2015 - As per Blended Revenue Requirements
    boolean showBlendedRevenueDetail = false;
    public Boolean getShowBlendedRevenueRecognitionDetail() {return showBlendedRevenueDetail;}
    public List<ProductRuleCategoryWrapper> listCategoryWrap {get;set;}
    public Decimal totalRecognized {get;set;} 
    public Decimal totalDeferred {get;set;}
    public Decimal totalRemainingBlended {get ;set;}
    public List<SelectOption> lineItemForBlended ;
    public Id revRecRuleId ;
    public string indexString {get;set;}
    
    //Iniltilize Wrapper class
    CalculateBlendedWrapper wrapCalculation = new CalculateBlendedWrapper();
    
    //Variable to hold the selected row number of wrapper
    public integer startRowNumber {get;set;}
    public integer endRowNumber {get;set;}
    public integer lineItemRowNumber{get;set;}
    public string lineItemNumber {get ; set;}
    
    //Added on - 09/24/2015 
    //Variables for split functionality
    public String categoryToBeSplit {get;set;}
    public String typeOfCategoryScreen {get;set;} //Either parent or Child
    public Id categoryParentId{get;set;}
    public Decimal originalLineItemAmount {get;set;}
    public Decimal originalLineItemQty {get;set;}
    public String lineItemRow {get;set;}
    public Decimal totalSplitRecognized {get;set;}
    public Decimal totalSplitDeferred {get;set;}
    public String catTypeValue {get;set;} 
    public Integer sequenceRow {get;set;}
    public List<ProductRuleCategoryWrapper> listSplitCategoryWrap {get;set;}
    public boolean ShowSplitBlendedRevenueRecognitionDetail {get;set;}
    public Decimal remainingSplitQty {get;set;}
    public Decimal remainingSplitPercent {get;set;}
    public Decimal remainingSplitAmount {get;set;}
    Integer screenNum;
    public String categoryToBeSplitParent;
    public Set<Id> setCategoriesToBeDeleted ; 
    public Set<Id> setSplitCategoriesToBeDeleted;  
    public Decimal initialResidual = 0.00; 
    public Decimal initialPercent = 0.00;
    public Decimal residualAmount = 0.00;
        
    //Code added - 11 july 2016 - AM ISSUE 
    public Date amStartDate ;
    public Date amEndDate ;
    
    //Code added - 13 July 2018 - Header to chnage as schedule page
    public Boolean isMultiCurrencyEnabled {get; set;}
    public Decimal oppTotalAmountWei {get;set;}
    public String userCurrencyIsoCode {get; set;}
    public String oppLineTotalOpportunity{get;set;}
    public String revRecOppTotalRecognized{get;set;} 
    public String revRecOppTotalDeferred{get;set;}
    public String revRecOppTotalResidual{get;set;}  
    public String oppLineTotalOpportunityWei{get;set;}
    public String revRecOppTotalDeferredWei{get;set;}
    public String revRecOppTotalResidualWei{get;set;}  
    public Opportunity opp {get;set;}
    private RevRecRules__c rule;
    
    //Map is used to  hold parent with list of splits
    Map<Id, List<RevRecProductRuleCategory__c>> mapParentIdWithListOfSplits = new Map<Id, List<RevRecProductRuleCategory__c>>();
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdRuleCatResult = Utility.getFieldPermissions('RevRecProductRuleCategory__c');
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdRuleMilesResult = Utility.getFieldPermissions('RevRecProductRuleMilestone__c');
    Static Map<String, Schema.DescribeFieldResult> mapfieldProdRuleResult = Utility.getFieldPermissions('RevRecProductRule__c');
    
    //Set to hold all parent's id in split functonality
    Set<Id> setParentScreenCategoryIds = new Set<Id>();
     
    //List of category  to be shown on page 
    List<RevRecRuleCategory__c> revRecRulesCategory = new List<RevRecRuleCategory__c>();
    public List<RevRecRuleCategory__c> getRevRecRulesCategory() {
        return revRecRulesCategory;
    }
    
    public boolean getShowAmortizeDetail() {return showAmortizeDetail;}
    public boolean getShowMilestoneDetail() {return showMilestoneDetail;}
    boolean showDevideEvenlyDetail = false;
    public boolean getShowDevideEvenlyDetail() {return showDevideEvenlyDetail;}
    boolean showByPeriodOrExactDetail = false;
    public boolean getShowByPeriodOrExactDetail() {return showByPeriodOrExactDetail;}
    boolean showOffsetDetail = false;
    public boolean getShowOffsetDetail() {return showOffsetDetail;}
    boolean showSingleTransDetail = false;
    public boolean getShowSingleTransDetail() {return showSingleTransDetail; }
    List<RevRecProductRuleMilestone__c> revRecProductRuleMilestones;
    public List<RevRecProductRuleMilestone__c> getRevRecProductRuleMilestones() {
        return revRecProductRuleMilestones;
    } 
        
    //Code adonCded - 06/13/2015 - As per Blended revenue recognition
    List<RevRecProductRuleCategory__c> revRecProductRuleCategories;
    public List<RevRecProductRuleCategory__c> getRevRecProductRuleCategories() {
        return revRecProductRuleCategories;
    }
    
    //Code modified - 11/26/2014- Change value of Revenue % to % only   
    public List<SelectOption> getMilestoneOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('percent','%'));
        options.add(new SelectOption('amount','Amount'));
        options.add(new SelectOption('qty','Qty'));
        return options;
    }  
    
    //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements
     public List<SelectOption> getAmortizeMilestoneOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('percent','%'));
        options.add(new SelectOption('amount','Amount'));
        options.add(new SelectOption('qty','Qty'));
        return options;
    }   

    //Code added - 06/13/2015 - As per Blended revenue requirement
    public List<SelectOption> getBlendedOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Percent','PERCENT'));
        options.add(new SelectOption('Amount','AMOUNT'));
        options.add(new SelectOption('Qty','QUANTITY'));
        return options;
    }
    
    //Code added - 07.17.2018 - As per header requirement same as schedule page
    public Opportunity getOpportunity() { return theOppty; }  
    
    boolean showTotalPeriod = false;
	public boolean adjustmentCalc;
    
    public RevRecProductRuleController () {
        
        changedRuleType = '';
        MilestoneDateSource = '';
        totalRecognized = 0.00;
        totalDeferred = 0.00;
        totalRemainingBlended = 0.00;
        startRowNumber = 0;
        lineItemRowNumber = 0;
        lineItemNumber = ''; 
        endRowNumber = 0;
        revRecRuleId = null;
        indexString = '0';
        selectedAmType = '1';
        errorMsg = '';
        setMilesIdToBeDeleted = new Set<Id>();
        isShowAdjuctAndPricingButton = false;
        hideErrorOnSave = false;
        
        //Initilizing Split variables
        originalLineItemAmount = 0.00;
        originalLineItemQty = 0.00;
        remainingSplitQty = 0.00;
        remainingSplitPercent = 0.00;
        remainingSplitAmount = 0.00;
        lineItemRow = '';
        totalSplitDeferred = 0.00;
        totalSplitRecognized = 0.00;
        catTypeValue = '';
        sequenceRow = 0;
        screenNum = 0;
        categoryToBeSplitParent = '';
        startDateStringDefault = '';
        endDateStringDefault = '';
        listCategoryWrap = new List<ProductRuleCategoryWrapper>(); 
        setCategoriesToBeDeleted = new Set<Id>();
        setSplitCategoriesToBeDeleted = new Set<Id>();
        listSplitCategoryWrap = new  List<ProductRuleCategoryWrapper>();
        mapParentIdWithListOfSplits = new Map<Id, List<RevRecProductRuleCategory__c>>();
        RevRecUtil.AppSetting = theSetting;
        IsInitializZero = false;
        IsLIAmountChanged = false;
        RevRecRulesMilestones = new List<RevRecRuleMilestone__c>();
        editable = false;
        errVisibility = false;
    	defaultOverridden = false;
    	adjustmentCalc = false;
        isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        userCurrencyIsoCode = userInfo.getDefaultCurrency();    
        opp = new Opportunity();
        opp.CloseDate = Date.Today();
        rule =  new RevRecRules__c();
        
        //Load defaults
        init();
    }
    
    //Init method
    public void init() {
    	
        Decimal sumOfCatRecogRev = 0.00;      
        Decimal sumOfCatDeferRev = 0.00; 
        showValidateAMAgainstLI = true;
        
        //Query through app setting
        List<RevRecAppSetting__c> theSettingList = [select Id, Is_Closed_Date_Validation__c, Name, Opportunity_Stage__c, Opportunity_Type__c, Selected_Start_Date_Types__c,
                                                            Selected_End_Date_Types__c, Time_of_Month_Selection_Types__c,  Certain_date_of_month__c,
                                                            Certain_weekday__c, Certain_weekday_day__c, Certain_days_before_last_weekday__c,
                                                            Time_of_Month_Selection_Types_tr__c,Certain_date_of_month_tr__c,
                                                            Certain_days_before_last_weekday_day__c, Certain_weekday_tr__c, Certain_weekday_day_tr__c, 
                                                            cron_job_id__c,Validate_Amortized_Milestones_Against_Li__c FROM  RevRecAppSetting__c 
                                                            WHERE Name='AppSetting' LIMIT 1 ]; 
        
        //Checking if app setting exist : if not create new
        if (theSettingList.Size() == 0 )
            theSetting =  new RevRecAppSetting__c(Name='AppSetting',  Time_of_Month_Selection_Types__c = '1');            
        else {
             
            theSetting = theSettingList[0];
            if(theSettingList[0].Validate_Amortized_Milestones_Against_Li__c == false) {
                showValidateAMAgainstLI = false;
                errorMsg = '(You cannot update milestone amount. Please check Validate Amortize Milestone Against Line Item on Application Setting data)';
            }
        }
            
        //Fetching all ORG-Date fields related to opportunity and opportunity line items
        allDates = RevRecHelper.getAllOpportunityFieldsWithDateType();
        
        opportunityId =String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('opportunityId'));
        theOppty = (Opportunity)RevRecHelper.SelectAllFieldsForObject('Opportunity', opportunityId);
        lineItemId =  String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('opportunityLineItemId'));
        salesforceTheme = ApexPages.currentPage().getParameters().get('salesforceTheme');
        
        utl = new Utility(theOppty);
        oli = RevRecHelper.GetLineItemWithAllFeilds(lineItemId);
        
        if(theOppty.ContractId != null)
        	contract = RevRecHelper.GetContractWithAllFeilds(theOppty.ContractId);
        else
        	contract = new Contract();
        
        lineItem = 
                [SELECT Id, Name , TotalPrice, Quantity, ListPrice, UnitPrice, PricebookEntry.Name, PricebookEntry.product2.id, RevRecRule__c, Rule_Assignment__c,
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
                    RevRecRule__r.Start_Percentage__c ,
                    RevRecRule__r.End_Percentage__c ,
                    RevRecRule__r.Is_Split_Categories__c,
                    RevRecRule__r.Enable_Manual_Forecast__c,
                    RevRecRule__r.Forecast_With_Zero_Value__c,
                    RevRecOpportunityLineItem__r.Id,
                    RevRecOpportunityLineItem__r.RevRecRule__c,
                    RevRecOpportunityLineItem__r.Rule_Assignment__c,
                    RevRecOpportunityLineItem__r.RecognizedRev__c,
                    RevRecOpportunityLineItem__r.Allocated__c,
                    RevRecOpportunityLineItem__r.DeferredRev__c,
                    RevRecOpportunityLineItem__r.Remaining_Amount__c,
                    RevRecOpportunityLineItem__r.Remaining_Percentage__c,
                    RevRecOpportunityLineItem__r.Remaining_Qty__c,
                    PricebookEntry.product2.RevRecRule__r.Milestone_Type__c,
                    RevRecOpportunityLineItem__r.ResidualAmount__c,
                    RevRecOpportunityLineItem__r.ResAmtWei__c,
                    RevRecOpportunityLineItem__r.CalculatedAt__c 
                FROM OpportunityLineItem WHERE Id = :lineItemId];
        
        //Code added - 13 July 2018 - Change header as schedule page
        if(!isMultiCurrencyEnabled && lineItem.TotalPrice != null)
            oppTotalAmountWei = (lineItem.TotalPrice * theOppty.Probability)/100;
        
        //Checking for multi currency enable
        //Code added - 02/18/2015 - As per Advance currency managemnet issue
        if(isMultiCurrencyEnabled) {
        	
            //Checking for null 
            if(lineItem.TotalPrice != null)
                oppLineTotalOpportunity =  utl.calculateAmountInCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), lineItem.TotalPrice);
            else
                oppLineTotalOpportunity = theOppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(lineItem.TotalPrice != null)
                oppLineTotalOpportunityWei =  utl.calculateAmountInCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), (lineItem.TotalPrice * theOppty.Probability)/100);
            else
                oppLineTotalOpportunityWei = theOppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null 
            if(lineItem.RevRecOpportunityLineItem__r.RecognizedRev__c != null)
                revRecOppTotalRecognized = utl.calculateAmountInCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.RecognizedRev__c);
            else
                revRecOppTotalRecognized = theOppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //checking for null
            if(lineItem.RevRecOpportunityLineItem__r.DeferredRev__c != null)
                revRecOppTotalDeferred =   utl.calculateAmountInCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.DeferredRev__c);
            else
                revRecOppTotalDeferred = theOppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(lineItem.RevRecOpportunityLineItem__r.ResidualAmount__c != null)
                revRecOppTotalResidual =   utl.calculateAmountInCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.ResidualAmount__c);    
            else
                revRecOppTotalResidual = theOppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
            
            //Checking for null
            if(lineItem.RevRecOpportunityLineItem__r.ResAmtWei__c != null)
                revRecOppTotalResidualWei =   utl.calculateAmountInCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), lineItem.RevRecOpportunityLineItem__r.ResAmtWei__c);
            else
                revRecOppTotalResidualWei = theOppty.get('CurrencyIsoCode') + ' 0.00' + '<br/>' + '( ' + userCurrencyIsoCode + ' 0.00 )';
        }    
        
        rule = lineItem.RevRecRule__r;
        
        product2 = RevRecHelper.GetProduct2WithAllFeilds(lineItem.PricebookEntry.Product2.Id);
        
        //Code added for Validation Issue
        List<RevRecOpportunityLineItemSchedule__c> schedules = [SELECT Id, RecognizedRev__c, RevRecOpportunityLineItem__c
    															FROM RevRecOpportunityLineItemSchedule__c
    															WHERE RevRecOpportunityLineItem__c =: lineItem.RevRecOpportunityLineItem__r.Id];
  		
        if(rule  != null)
            revRecRuleId = rule.Id;
        
        if (lineItem.RevRecOpportunityLineItem__r != null) {
            revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
            
            if (revRecLineItem != null) {
                
                //Code added - 01/19/2015 - As per Amortized Milestone Rule Requirements - Add Milestone_Date_Source__c , Milestone_Date_Source_Label__cin Query
                //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements - Add  Actual_Qty__c, Actual_Amount__c in Query                                                                     
                List<RevRecProductRule__c> overrideRuleList = [SELECT Id, name, Divide_By__c, initial_amount__c, initial_amount_type__c, Offset_Period__c, 
                                                                    offset_type__c,Period__c, Period_or_Exact_Days__c, Recognition_Type__c, Start_Percentage__c, End_Percentage__c,
                                                                    Milestone_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Start_Date__c, 
                                                                    End_Date__c, Total_Period__c, InitialComments__c, OffsetComments__c,
                                                                    ResidualComments__c,RevRecOpportunityLineItem__c,
                                                                    Prior_Rule_Type__c, Is_Split_Categories__c, Enable_Manual_Forecast__c, Is_Manual_Update__c,
                                                                    Forecast_With_Zero_Value__c, Man_Ini_To_Zero__c, AM_Manual_Cal__c,Is_Default_Overriden__c,
                                                                    (SELECT ID, Name, Milestone_Name__c, Milestone_Sequence__c, Percent__c, Amount__c, Sales_Manual_Amount__c,
                                                                     Qty__c, Milestone_Date__c, RevRecProductRule__c,Date_Text__c, Projected_Percent__c,
                                                                     Actual_Qty__c, Actual_Amount__c, Actual_Percent__c, Milestone_Date_Source__c, Milestone_Date_Source_Label__c, Projected_Amount__c, Projected_Qty__c                                                                         
                                                                     FROM RevRecProductRuleMilestones__r ORDER BY Milestone_Sequence__c),  
                                                                    //Code added  06/13/2015 -  As per Blended revenue recognition
                                                                    (SELECT Id, Name, Is_Split__c ,Line_Item__c, Amount__c, Category_End_Date__c, Category_Start_Date__c
                                                                    , Category_Type__c, Percent__c, Qty__c, Recognition_Type__c, RevRecProductRule__c,Ultimate_Parent__c,
                                                                    Sequence__c , Recognized_Amount__c, Deferred_Amount__c , Actual_Start_Date__c,Actual_End_Date__c, 
                                                                    Projected_Percent__c, Projected_Qty__c, Projected_Amount__c
                                                                    ,RevRecProductRuleSplitCategory__c,Actual_Deferred__c , Sub_Category_support__c FROM RevRecProductRuleCategorys__r 
                                                                    WHERE RevRecProductRuleSplitCategory__c = NULL ORDER BY Sequence__c)
                                                                    
                                                                    FROM RevRecProductRule__c WHERE RevRecOpportunityLineItem__c = :revRecLineItem.Id 
                                                                    LIMIT 2];
                 
                // Code added - 11/5/2014 - As per Amortized Milestone Rule Requirements
                //Check if Rule Ovveride exist only then use that else use the new Overridde rule for line item    
                
                if (overrideRuleList.size() == 1) {
                	overrideRule =  overrideRuleList[0] ; 
                	defaultOverridden = overrideRuleList[0].Is_Default_Overriden__c;
                }            
                else {
                    for(RevRecProductRule__c ovRule:  overrideRuleList) {               
                        if(!ovRule.Name.contains('[overridden] ')) 
                            overrideRule =  ovRule;
                    }
                }
            }
            
            if(overrideRule != null && overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE && 
               defaultOverridden == true) {
                   if(overrideRule.Residual_Amount__c == 0.00)
                   	   adjustmentCalc = true;
                   else {
                       adjustmentCalc = false;
                       if(overrideRule.Residual_Amount_Type__c == 'Percent') {
                           initialResidual = ((overrideRule.Residual_Amount__c * lineItem.TotalPrice)/100).setScale(2);
                           initialPercent = overrideRule.Residual_Amount__c;
                       }
                       else if(overrideRule.Residual_Amount_Type__c == 'Amount') {
                           initialResidual = overrideRule.Residual_Amount__c;
                           initialPercent = ((overrideRule.Residual_Amount__c * 100)/lineItem.TotalPrice).setScale(2);
                       }
                   }
               }

            //Checking for null
            if (overrideRule != null) {
                
                //Get milestone and categories
                RevRecProductRuleMilestones =  overrideRule.RevRecProductRuleMilestones__r;
                
                //Code added - 06/13/2015 - As per Blended Revenue Recognition requirement
                revRecProductRuleCategories = overrideRule.RevRecProductRuleCategorys__r;
                
                //Variables to hold recognized and deferred amount
                Decimal recognizedAmount ;
                Decimal deferredAmount;
                Decimal actualDeferred;
                Decimal outstandingBalance = lineItem.TotalPrice;
                Decimal actualCatDifference = 0.00;
                String msg = '';
                
                //Loop through RevRecProduct Category 
                for(RevRecProductRuleCategory__c prodCat : revRecProductRuleCategories) {
                     
                    //Initilize variables
                    deferredAmount = 0.00;
                    recognizedAmount = 0.00;
                    actualDeferred = 0.00;
                    
                    //Setting app setting
                    RevRecUtil.appSetting = theSetting;
                
                    //Calling method to calculate recognized and deferred amount
                    wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlended(prodCat, outstandingBalance, recognizedAmount, deferredAmount, lineitem, msg, revRecProductRuleCategories, null, actualDeferred, overrideRule);
                    recognizedAmount = wrapCalculation.recognizedAmount;
                    deferredAmount = wrapCalculation.deferredAmount;
                    actualDeferred = wrapCalculation.actualDeferred;
                    outstandingBalance = wrapCalculation.outStandingBalance;
                    actualCatDifference = wrapCalculation.actualCatDifference;
                    msg = wrapCalculation.msg;   
                    
                    //Set values in Product Category
                    prodCat.Recognized_Amount__c = recognizedAmount;
                    prodCat.Deferred_Amount__c = deferredAmount;
                    prodCat.Actual_Deferred__c = actualDeferred;
                    
                    outstandingBalance = outstandingBalance - actualCatDifference;
                }  
                //Set  dates to null default
                Date actualStartDate = null;
                Date actualEndDate = null;
                
                /** ** ** *** Code added as per split functionality ** ** ** ***/
                //mapParentIdWithListOfSplits
                //Query over Product Categories
                
                for(RevRecProductRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c, Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                                                Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Ultimate_Parent__c,
                                                                RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,Sub_Category_support__c,
                                                                (Select Id,Is_Split__c , Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                 Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Ultimate_Parent__c,
                                                                 Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c, Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                                                 RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,Sub_Category_support__c From RevRecProductRuleSplitCategorys__r 
                                                                 ORDER BY Sequence__c) FROM RevRecProductRuleCategory__c
                                                                Where RevRecProductRule__c =: overrideRule.Id]) {
                                                                               
                    //Checking for size of child - Populate map with values
                    if(revCategory.RevRecProductRuleSplitCategorys__r.Size() > 0)
                        mapParentIdWithListOfSplits.put(revCategory.Id, revCategory.RevRecProductRuleSplitCategorys__r);
                }
            }
        } 
        
        if (revRecLineItem == null) 
            revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name, opportunity__c = opportunityId);
     
        Map<String, RevRecRuleMilestone__c> mapRevRecMileStoneWithName = new Map<String, RevRecRuleMilestone__c>();
        List<RevRecRuleCategory__c> revRevRuleCategories = new List<RevRecRuleCategory__c>();
          
        //If override rule is null then do this
        if (overrideRule == null) { 
            
            revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
            overrideRule = new RevRecProductRule__c();
            
            //Code added - 11/05/2014 - As per Amortized Milestone Rule Requirements            
            List<RevRecRuleMilestone__c> revRecRulesMilestones = new List<RevRecRuleMilestone__c>();
             
             //Code added -  06/13/2015 - As per Blended revenue recognition requirement
             revRecProductRuleCategories = new  List<RevRecProductRuleCategory__c>();
            
            //If rule != null then   fetch all the mileestones relted to it
            if (rule != null){
                
                //Code modified - 01/19/2015 - As per Milestone date automation
                //Add field in query Milestone_Date_Source__c , AppRopozSLN__Milestone_Date_Source_Label__c 
                
                //Code modified - 11/05/2014 - As per Amortized Milestone Rule Requirements 
                //Add field in query Actual_Amount__c, Actual_Qty__c, MileStone_Date__c, Amount__c, Qty__c,
                revRecRulesMilestones = [SELECT Id, name, Milestone_Sequence__c, Milestone_Name__c, Percent__c ,Amount__c, 
                                        Qty__c, Actual_Amount__c,Actual_Percent__c,Actual_Qty__c,MileStone_Date__c, Projected_Amount__c,
                                        Milestone_Date_Source__c, Sales_Manual_Amount__c, Milestone_Date_Source_Label__c, Projected_Percent__c, Projected_Qty__c
                                        FROM RevRecRuleMilestone__c WHERE RevRecRule__c = :rule.Id 
                                        ORDER BY Milestone_Sequence__c];
              
              //Code added - 06/13/2015 - As per Blended Revenue Recognition requirement
              revRevRuleCategories = [SELECT Id, Name, Line_Item__c, Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                             Percent__c, Qty__c, Recognition_Type__c, RevRecRule__c, Sequence__c , Actual_Start_Date__c, 
                                             Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                             Actual_End_Date__c FROM RevRecRuleCategory__c WHERE RevRecRule__c =: rule.Id 
                                             ORDER BY Sequence__c];   
            } 
            
            //Instantiate util class
            RevRecUtil theUtil = new RevRecUtil();
			
            //Code modified - 06/13/2015 - as per Blended Revenue Recognition requirement
            String msg = theUtil.CalculateOverrideRuleFromRevRecRule(theOppty, oli, Product2,  rule, overrideRule, revRecRulesMilestones, revRecProductRuleMilestones, mapRevRecMileStoneWithName, revRevRuleCategories, revRecProductRuleCategories, utl, contract);
            if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Total_Period__c',Constants.PERMISSION_UPSERT))
                overrideRule.Total_Period__c = null;
		
            //Code added - 11 july 2016 - AM ISSUE
            amStartDate = overrideRule.Start_Date__c;
            amEndDate = overrideRule.End_Date__c;
             
            //Cheking for null
            if (msg != '')
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
        }
        
        if(overrideRule.Start_Date__c != null) {
            startDateStringDefault =  formatDate(overrideRule.Start_Date__c);
        }

        if(overrideRule.End_Date__c != null) {
            endDateStringDefault =  formatDate(overrideRule.End_Date__c);
        }

        //Loop through Product Category and populate in wrapper class
        integer i = 0;
        
         if(overrideRule.Recognition_Type__c ==  Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
             
             for(RevRecProductRuleCategory__c cat : revRecProductRuleCategories) {
                 
                 //Calling method to get dates from the date field
                 formatDateForOverrideCategory(cat);
                 
                 //Inilitilize list of select option
                 lineItemForBlended = new List<SelectOption>();
                 
                 //Loop over category sequence
                 for(Integer j=0 ; j< cat.Sequence__c ; j++)
                     lineItemForBlended.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
                 
                 //Populare wrapper
                 listCategoryWrap.add(new ProductRuleCategoryWrapper(cat, i,  lineItemForBlended, false));
                 
                 totalRecognized += cat.Recognized_Amount__c;
                 totalDeferred += cat.Actual_Deferred__c;
                 sumOfCatRecogRev += cat.Recognized_Amount__c.setScale(2);
                 sumOfCatDeferRev += cat.Actual_Deferred__c.setScale(2);
                 
                 i++; 
                 
                 if(sumOfCatRecogRev-totalRecognized.setScale(2) >= 0.01) {
                     Decimal recogAmount = cat.Recognized_Amount__c.setScale(2);
                     recogAmount -= (sumOfCatRecogRev-totalRecognized);
                     cat.Recognized_Amount__c = recogAmount;
                     sumOfCatRecogRev -= (sumOfCatRecogRev-totalRecognized);
                 } else if(totalRecognized-sumOfCatRecogRev >= 0.01) {
                     Decimal recogAmount = cat.Recognized_Amount__c.setScale(2);
                     recogAmount += (totalRecognized-sumOfCatRecogRev);
                     cat.Recognized_Amount__c = recogAmount;
                     sumOfCatRecogRev += (totalRecognized-sumOfCatRecogRev);
                 }
                 if(sumOfCatDeferRev-totalDeferred.setScale(2) >= 0.01) {
                     Decimal deferAmount = cat.Actual_Deferred__c.setScale(2);
                     deferAmount -= (sumOfCatDeferRev-totalDeferred);
                     cat.Actual_Deferred__c = deferAmount;
                     sumOfCatDeferRev -= (sumOfCatDeferRev-totalDeferred);
                 } else if(totalDeferred-sumOfCatDeferRev >= 0.01) {
                     Decimal deferAmount = cat.Actual_Deferred__c.setScale(2);
                     deferAmount += (totalDeferred-sumOfCatDeferRev);
                     cat.Actual_Deferred__c = deferAmount;
                     sumOfCatDeferRev += (totalDeferred-sumOfCatDeferRev);
                 }
                 
                 if((totalRecognized+totalDeferred) == lineItem.TotalPrice) {
                     if((sumOfCatRecogRev+sumOfCatDeferRev) < (totalRecognized+totalDeferred)) {
                         if(totalRecognized != 0.00) {
                             if(cat.Recognized_Amount__c != 0.00) {
                                 cat.Recognized_Amount__c += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
                                 Decimal totalRec = totalRecognized.setScale(2);
                                 totalRec += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
                                 totalRecognized = totalRec;
                                 sumOfCatRecogRev = totalRec;
                             }
                         } else if(totalDeferred != 0.00) {
                             if(cat.Actual_Deferred__c != 0.00) {
                                 cat.Actual_Deferred__c += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
                                 Decimal totalDef = totalDeferred.setScale(2);
                                 totalDef += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
                                 totalDeferred = totalDef;
                                 sumOfCatDeferRev = totalDef;
                             }
                         }
                     }
                 }
             }
        	
            //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
            //Remianing amount, percentage, quantity
            revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
            
             if(lineItem.TotalPrice > 0) {
                revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
                revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
             }else {
                 revRecLineItem.Remaining_Percentage__c = 0.00;
                 revRecLineItem.Remaining_Qty__c  = 0.00;
             }
         }
         
        //If override rule is milestone
        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
            
                Date mileStoneDate = null;
                Double recognized = 0.00;
                
                //Loop through milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                   
                   //Totaal recognized
                   recognized += item.Actual_Amount__c != null ? item.Actual_Amount__c : 0.00;
                   
                    //get the start date and end date    
                    String RevRecMileStoneDateSourceField = item.Milestone_Date_Source__c;
                        
                    //Checking if Date source is produuct / Opportunity /  Manual  
                    if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY)){
                        if(RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)){
                            string fieldName = RevRecMileStoneDateSourceField.subString(20, RevRecMileStoneDateSourceField.length()); 
                            mileStoneDate = (Date)oli.get(fieldName);
                        }
                        else {
                            string fieldName = RevRecMileStoneDateSourceField.subString(12, RevRecMileStoneDateSourceField.length()); 
                            mileStoneDate = (Date)theOppty.get(fieldName);
                        }
                    } else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                        string fieldName = RevRecMileStoneDateSourceField.subString(8, RevRecMileStoneDateSourceField.length());
                        mileStoneDate = (Date)product2.get(fieldName);
                    } else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                        string fieldName = RevRecMileStoneDateSourceField.subString(9, RevRecMileStoneDateSourceField.length());
                        mileStoneDate = (Date)contract.get(fieldName);
                    } else {
                        
                        if(overrideRule == null)
                            mileStoneDate = null;
                        else
                            mileStoneDate = item.MileStone_Date__c;
                    }
                    
                    //Checking if Date source is produuct / Opportunity /   Manual  
                   if ((RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) 
                                        || RevRecMileStoneDateSourceField != null 
                                        && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY_COLON)) {
                   
                        //Getting field label from field Api name 
                          if(allDates.containsKey(RevRecMileStoneDateSourceField)) {
                             milestoneDateSource = allDates.get(RevRecMileStoneDateSourceField);
                          }
                      } else {
                        milestoneDateSource = constants.MILESTONE_DATE_MANUAL;
                      }
                    //Set milestone date label
                    item.Milestone_Date_Source_Label__c = milestoneDateSource;
                    
                    //Set milestone date from date variable
                    item.Milestone_Date__c = mileStoneDate;
                    
                    item.Date_Text__c = formatDate(item.Milestone_Date__c);
                 }

                //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
                //Remianing amount, percentage, quantity  
                revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - recognized).setScale(2);
                
                if(lineItem.TotalPrice > 0) {
                    revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
                    revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
                }else {
                    revRecLineItem.Remaining_Percentage__c = 0.00;
                    revRecLineItem.Remaining_Qty__c = 0.00;
                }
            }      
        assignVisualBlocks();
        changedRuleType = overrideRule.Recognition_Type__c;      
    }
    
    //Getting divided by options
    public List<SelectOption> getDividedByOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Period','Divided evenly by whole periods:'));
        options.add(new SelectOption('nonProrate','Prorate first and last periods by Exact Days'));
        options.add(new SelectOption('Prorate','Prorate first and last periods by Percentage'));
        
        return options;
    }   
   
   //Getting periods options
    public List<SelectOption> getPeriodExactOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('period','By Whole Periods (for all other periods)'));
        options.add(new SelectOption('exact','By Exact Days (for all other periods)')); 
         
        return options;
    }   
    
    //Method to be called on changing recognition period
    public PageReference ChangeRecognitionPeriod() {
        assignVisualBlocks();
        return null;
    }
    
    //Default method 
    public void assignVisualBlocks() {
        showByPeriodOrExactDetail = false;
        showDevideEvenlyDetail = false;
        showOffsetDetail = false;
        showAmortizeDetail = false;
        showMilestoneDetail = false;
        showSingleTransDetail = false;
        showAmortizeMilestoneDetail = false;
        if (overrideRule.Recognition_Type__c == 'Single Transaction')
            showSingleTransDetail = true;
        else if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE || overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE ){
            
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)
                showAmortizeMilestoneDetail = true;
            else
                showAmortizeDetail = true;
            if (overrideRule.End_Date__c == null)
                showTotalPeriod = true;
            else
                showTotalPeriod = false;
                
            if (overrideRule.Period__c == 'monthly'){
                showByPeriodOrExactDetail = true;
                showDevideEvenlyDetail = true;
                showOffsetDetail = true;
            } else if (overrideRule.Period__c == 'weekly'){
                showOffsetDetail = true;
            } else if (overrideRule.Period__c == 'quarterly'){
                showOffsetDetail = true;
            } else if (overrideRule.Period__c == 'yearly'){
                showOffsetDetail = true; 
            } else if (overrideRule.Period__c == 'daily'){
                showOffsetDetail = true;
            }             
        } else if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE)
            showMilestoneDetail = true;
         
        //Code added - 06/13/2015 - As per Blended Revenue Recognition Requirement
        else if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
            showBlendedRevenueDetail = true;
            showDevideEvenlyDetail = true;
            showByPeriodOrExactDetail = true;
        }
    }   
    
    //Cancel method to redirect on main opportunity
    public PageReference cancel() {  
        return  new PageReference('/' + opportunityId) ;   
    } 
     
    //Method to save the override rule and Milestone and categories respectively
    public PageReference save() { 
        //Declaration
        Decimal sumOfCatRecogRev = 0.00;      
        Decimal sumOfCatDeferRev = 0.00; 
        
        if(overrideRule.Residual_Amount__c != null && overrideRule.Residual_Amount__c != 0.00) { 
            if(overrideRule.Residual_Amount_Type__c == 'Percent')
                residualAmount = (overrideRule.Residual_Amount__c * lineItem.TotalPrice)/100;
            else if(overrideRule.Residual_Amount_Type__c == 'Amount')
                residualAmount = overrideRule.Residual_Amount__c;
        }
        
        //Updating line item amount if it set from adjust from future revenue method
        if(IsLIAmountChanged){
            Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE_FROM_ADJUST = true;
            
            try {  	
                update lineItem; //Updating line item 
                overrideRule.AM_Manual_Cal__c = true;
            }catch(Exception ex) {
                System.debug('@@@@@@@@@@@@@@@@@@@@@@' + ex.getMessage());
            }
                        
            Constants.IS_LINE_ITEM_TOTAL_PRICE_CHANGE_FROM_ADJUST = false;
        }
        
        try {            
            /** Lightning start and end date from custom date picker **/
            if(String.isNotBlank(startDateString))  {  
                startDateString = startDateString.trim().replace(' ' , '');
                overrideRule.Start_Date__c = Date.parse(startDateString);
            } 
            
            if(String.isNotBlank(endDateString)) { 
                endDateString = endDateString.trim().replace(' ' , '');
                overrideRule.End_Date__c = Date.parse(endDateString);
            }
            
            String msg = '';
            String message = '';
            lineItemId =  ApexPages.currentPage().getParameters().get('opportunityLineItemId');
            lineItem = [SELECT Id,Name ,ListPrice, TotalPrice, Quantity, PricebookEntry.Name, RevRecOpportunityLineItem__r.Id, RevRecOpportunityLineItem__r.RecognizedRev__c,
                        RevRecOpportunityLineItem__r.DeferredRev__c, RevRecOpportunityLineItem__r.Remaining_Amount__c, RevRecOpportunityLineItem__r.Remaining_Percentage__c, Rule_Assignment__c, RevRecRule__c,
                        RevRecOpportunityLineItem__r.Remaining_Qty__c, Overriden_Rule_Assignment_Id__c,RevRecOpportunityLineItem__r.ResidualAmount__c, RevRecOpportunityLineItem__r.ResAmtWei__c,
                        RevRecOpportunityLineItem__r.CalculatedAt__c FROM OpportunityLineItem  WHERE Id = :lineItemId];
            
            if(lineItem.RevRecOpportunityLineItem__r == null){
                revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name,  opportunity__c = opportunityId);
                insert(revRecLineItem);
            } else 
                revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
            
            lineItem.RevRecOpportunityLineItem__c = revRecLineItem.id;
             
            if (overrideRule.RevRecOpportunityLineItem__c == null && Utility.checkFieldPermission(mapfieldProdRuleResult,'RevRecOpportunityLineItem__c',Constants.PERMISSION_UPSERT)) 
                overrideRule.RevRecOpportunityLineItem__c = revRecLineItem.Id;
            if (showTotalPeriod && Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT) && Utility.checkFieldPermission(mapfieldProdRuleResult,'Total_Period__c',Constants.PERMISSION_UPSERT))
                overrideRule.End_Date__c = null;
            else 
                overrideRule.Total_Period__c = null; 
           
            //Check for Recognition type 
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE || overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE ) {
                Constants.IS_BY_PASS_RULE_TRIGGER = true;
                if((overrideRule.End_Date__c == null || overrideRule.start_Date__c == null ) || overrideRule.start_Date__c > overrideRule.End_Date__c)
                    msg += label.START_AND_END_DATE_NOT_BLANK;
                
               if(utilHelper.yearDifference(overrideRule.start_Date__c , overrideRule.End_Date__c) > 10)
                    msg += constants.START_END_DATE_RANGE_EXCEED;
            }  
            //Check for null
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION || 
                overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE ) {
                
                //Checking for Closed date validation
                if(theSetting.Is_Closed_Date_Validation__c) {
               
                    //Code added- 09/01/2015 - As per new Revview requirement
                    if(theOppty.CloseDate > overrideRule.start_Date__c)
                        msg += constants.ERROR_MESSAGE_BASED_ON_DATES;
                    
                    else if(theOppty.CloseDate > overrideRule.End_Date__c) 
                        msg += constants.ERROR_MESSAGE_BASED_ON_DATES; 
                }
               //Checking for the date difference 
               //Added on 13 sept
               if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION &&
                    utilHelper.yearDifference(theOppty.CloseDate, overrideRule.Start_Date__c) > 10 )
                    msg += constants.START_END_DATE_RANGE_EXCEED;
               else if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE) {
                   Integer differenceCount = utilHelper.yearDifference(overrideRule.Start_Date__c != null ?  overrideRule.Start_Date__c :null, 
                                    overrideRule.End_Date__c != null ? overrideRule.End_Date__c : null);
                   Integer monthCount = utilHelper.monthDifference(overrideRule.Start_Date__c != null ?  overrideRule.Start_Date__c :null, 
                                    overrideRule.End_Date__c != null ? overrideRule.End_Date__c : null);
                   if((overrideRule.Period__c == 'daily' && monthCount > 24) || differenceCount > 10) {
                       msg += constants.START_END_DATE_RANGE_EXCEED; 
                   }
               }
            }    
            
           if(overrideRule.Divide_By__c == 'Prorate' ) {
                if(overrideRule.Start_Percentage__c == null)
                    overrideRule.Start_Percentage__c = 0.00;
                if(overrideRule.End_Percentage__c == null)
                    overrideRule.End_Percentage__c = 0.00;
                //Code is added on 05/05/2017 for urgent fixes on Amortize and Amortized Milestone
                //Check for rule start and end % total not exeed 100
                if(overrideRule.Start_Percentage__c != null || overrideRule.End_Percentage__c != null) {
                    
                    Decimal totalPercentage = overrideRule.Start_Percentage__c + overrideRule.End_Percentage__c;
                    
                    if(totalPercentage != 100.00) 
                        msg += Constants.RULE_START_AND_END_PERCENTAGE_NOT_MORE_THAN_100;
                }
            }
            //If message != null and page message 
            if(msg != '') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                return null;       
            }
            
            //Assign recogntion type
            overrideRule.Recognition_Type__c = changedRuleType;
             
            //Checking for Rule type
            if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE 
                    || (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE)) {
                
                overrideRule.Is_Default_Overriden__c = false;
                
                //Actual values
                Decimal actualAmount = 0.00;
                Decimal actualPercent = 0.00;
                Decimal actualQty = 0.00;
                
                //Projected values
                Decimal manualAmount = 0.00;
                Decimal manualPercent = 0.00;
                Decimal manualQty = 0.00;
                
                //Forecasted values
                Decimal amount = 0.00;
                Decimal percent = 0.00;
                Decimal qty = 0.00;
                
                //Loop over milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                    
                     //checking for milestone
                     if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                        
                        //Checking for date (Lightning case)
                        if(String.isNotBlank(item.Date_Text__c) && salesforceTheme != 'Theme3') {
                            
                            item.Date_Text__c = item.Date_Text__c.trim().replace(' ' , '');
                            
                            item.Milestone_Date__c = Date.parse(item.Date_Text__c); 
                            
                            item.Date_Text__c = '';
                        }

                        if(item.Amount__c != null)
                            amount += item.Actual_Amount__c;
                     }
                }
                
                if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE ) { 
                    message = '';
                    
	                if(adjustmentCalc == true)  
	                    message = utilHelper.showErrorAndAdjustRevenueButtons(utl, theOppty, isMultiCurrencyEnabled, isShowAdjuctAndPricingButton, revRecProductRuleMilestones, overrideRule, theSetting, lineItem, actualAmount, manualAmount, amount, 0.00, hideErrorOnSave, actualPercent, actualQty);
	                else { 
	                    if(defaultOverridden == true) {
	                        if(initialPercent == ((residualAmount*100)/lineItem.TotalPrice).setScale(2))
	                            message = utilHelper.showErrorAndAdjustRevenueButtons(utl, theOppty, isMultiCurrencyEnabled, isShowAdjuctAndPricingButton, revRecProductRuleMilestones, overrideRule, theSetting, lineItem, actualAmount, manualAmount, amount, residualAmount, hideErrorOnSave, actualPercent, actualQty);
	                        else 
	                            message = utilHelper.showErrorAndAdjustRevenueButtons(utl, theOppty, isMultiCurrencyEnabled, isShowAdjuctAndPricingButton, revRecProductRuleMilestones, overrideRule, theSetting, lineItem, actualAmount, manualAmount, amount, initialResidual, hideErrorOnSave, actualPercent, actualQty);
	                    }
	                    else
	                        message = utilHelper.showErrorAndAdjustRevenueButtons(utl, theOppty, isMultiCurrencyEnabled, isShowAdjuctAndPricingButton, revRecProductRuleMilestones, overrideRule, theSetting, lineItem, actualAmount, manualAmount, amount, residualAmount, hideErrorOnSave, actualPercent, actualQty);       
	                }
	                
	                List<String> splitMessage = new List<String>();
	                splitMessage.addAll(message.split('-'));
	                 
                	if(editable) {
	                    if(String.isNotBlank(splitMessage[0])) {
	                        if(splitMessage[0] == Constants.WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL){
	                            if(!hideErrorOnSave) {
	                                overrideRule.AM_Manual_Cal__c = true;
	                                isShowAdjuctAndPricingButton = true;
	                                hideErrorOnSave = true;
	                            }
	                            else {
	                                isShowAdjuctAndPricingButton = false;
	                            }
	                        } else
	                            isShowAdjuctAndPricingButton = true;
	                        
	                        return null;
	                    }  
	                    else {
	                    	overrideRule.AM_Manual_Cal__c = true;
	                    }
	                }
                }
            }
            
            lineItem.Overriden_Rule_Assignment_Id__c = overrideRule.Id;
            lineItem.Overridden_Rule__c = overrideRule.Name;
            
            update(lineItem);
            
            //Flags
            Constants.IS_BLANK_PRIOR_VAL = true;
            Constants.IS_BY_PASS_RULE_TRIGGER = false;
            
            //Checking for Rule type
            if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                
                overrideRule.Is_Default_Overriden__c = false;
                
                //List of miles to be deleted
                List<RevRecProductRuleMilestone__c> milesToDelete = new List<RevRecProductRuleMilestone__c>();
                
                //Checking for set size
                if(setMilesIdToBeDeleted.size() > 0) {
                    
                    //Loop over set ids
                    for(Id mileId : setMilesIdToBeDeleted) 
                        milesToDelete.add(new RevRecProductRuleMilestone__c( Id = mileId ));
                }
                
                //Checking for list size
                if(RevRecProductRuleMilestone__c.sObjectType.getDescribe().isDeletable()){
                    if(milesToDelete.size() > 0)
                        delete milesToDelete;
                }
                
                //Added on - 01/19/2015 - As per Milestone Date Automation
                Date mileStoneDate = null;
                    
                //Checking for Milesrtone type
                if (string.isNotBlank(overrideRule.Milestone_Type__c) && overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                    Decimal totalAmount = 0;
                    Decimal totalProAmount = 0;
                    for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        if (item.Actual_Amount__c != null || item.Projected_Amount__c != null) {
                            
                            if(item.Actual_Amount__c != null) {
                                totalAmount += item.Actual_Amount__c;
                            }
                            if(item.Projected_Amount__c != null) {
                                totalProAmount += item.Projected_Amount__c;
                            }
                            
                            if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                        } else 
                            msg += 'Milestone amount for "' + item.Milestone_Name__c +'"  need to be defined. ';
                        
                        //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                        //If true the do this 
                        if(isMultiCurrencyEnabled) {
                            
                            if(item.Actual_Amount__c != null) {
                                item.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), item.Actual_Amount__c)).replace('<br/>', '');
                                item.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), item.Actual_Amount__c));
                            } else {
                                item.Converted_Actual_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                item.Cor_Act_Amt__c = 0.00;
                            }
                        }
                    }
                    
                    if ((totalAmount - lineItem.TotalPrice) > 0.0001 || (totalProAmount - lineItem.TotalPrice) > 0.0001)
                        msg += 'The Total Amount for the milestones exceeds the current product Line Item total. Please go back to the opportunity to increase Line Item amount or adjust milestone amounts.';
                } else if (string.isNotBlank(overrideRule.Milestone_Type__c) && overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                    Decimal totalQty = 0;
                    Decimal totalProQty = 0;
                    
                    for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                        
                        if (item.Actual_Qty__c != null || item.Projected_Qty__c != null) {
                            if(item.Actual_Qty__c != null) {
                                item.Actual_Amount__c = ((lineItem.TotalPrice)* item.Actual_Qty__c)/ (lineItem.Quantity).setScale(2);
                                totalQty += item.Actual_Qty__c;
                            }
                            
                            if(item.Projected_Qty__c != null) {
                                item.Projected_Amount__c = ((lineItem.TotalPrice)* item.Projected_Qty__c)/ (lineItem.Quantity).setScale(2);
                                totalProQty += item.Projected_Qty__c;
                            }
                            if(item.RevRecProductRule__c == null )
                                    item.RevRecProductRule__c = overrideRule.Id;                    
                        } else
                            msg += 'Milestone qty for "' + item.Milestone_Name__c +'"  need to be defined. ';                 
                        
                        //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                        //If true the do this 
                        if(isMultiCurrencyEnabled) {
                            
                            if(item.Actual_Amount__c != null) {
                                item.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), item.Actual_Amount__c)).replace('<br/>', '');    
                                item.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), item.Actual_Amount__c));    
                            } else {
                                item.Converted_Actual_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )'; 
                                item.Cor_Act_Amt__c = 0.00;
                            }
                        }
                    }
                    
                    if (totalQty > lineItem.Quantity || totalProQty > lineItem.Quantity) {
                        msg += 'The total quantity for the milestones exceeds the current product Line Item quantity. Please go back to the opportunity to increase Line Item amount or adjust milestone quantity.';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }
                } else {
                    Decimal totalPercent = 0;
                    Decimal totalProPercent = 0;
                    for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        if (item.Actual_Percent__c != null || item.Projected_percent__c != null) {
                            
                            if(item.Actual_Percent__c != null) {
                                
                                totalPercent += item.Actual_Percent__c; 
                                item.Actual_Amount__c = (((lineItem.TotalPrice)* item.Actual_Percent__c)/100).setScale(2);
                            }
                              
                            if(item.Projected_percent__c != null) {
                                
                                totalProPercent += item.Projected_percent__c; 
                                item.Projected_Amount__c = (((lineItem.TotalPrice)* item.Projected_percent__c)/100).setScale(2);
                            }
                            
                            if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                        } else 
                            msg += 'Milestone percentage for "' + item.Milestone_Name__c +'"  need to be defined. ';
                        
                        //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                        //If true the do this 
                        if(isMultiCurrencyEnabled) {
                            
                            if(item.Actual_Amount__c != null) {
                                item.Converted_Actual_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), item.Actual_Amount__c)).replace('<br/>', '');
                                item.Cor_Act_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), item.Actual_Amount__c));    
                            } else {
                                item.Converted_Actual_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                                item.Cor_Act_Amt__c = 0.00;
                            }
                        }
                    }
                    if((totalPercent - 100) > 0.0001 || (totalProPercent - 100) > 0.0001)
                        msg += 'Total percentage is over 100%';
                }
             }
            
            //Code is added on 07/07/2016
            //if, there is any error then return
            if(msg != '') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                return null;
            }
            
            //Code added - 11 july 2016 - AM ISSUE
            Boolean isRuleDateChangeFirstTime = false;
            if(overrideRule.Id == null && (overrideRule.Start_Date__c != amStartDate || overrideRule.End_Date__c != amEndDate))
                isRuleDateChangeFirstTime = true;
            
            if(IsInitializZero)
                overrideRule.Man_Ini_To_Zero__c = true;

            //Upserting overridden rule
            upsert(overrideRule);
       
            List<RevRecProductRuleMilestone__c> allMilestoneInDB = [SELECT Id FROM RevRecProductRuleMilestone__c WHERE RevRecProductRule__c = :overrideRule.Id];
            List<RevRecProductRuleMilestone__c> deletedMilestone = new List<RevRecProductRuleMilestone__c>();
           
            //Code added - 02/03/2015 - Checlkking if Rule is not amortized milestone
            //DO NOT DELETE MILESTONES
            for(RevRecProductRuleMilestone__c itemInDB : allMilestoneInDB) {
                boolean itemExistInWorkingList = false;
                for (RevRecProductRuleMilestone__c itemInWorkingList : revRecProductRuleMilestones) {
                    if (itemInWorkingList.Id != null && itemInWorkingList.Id == itemInDB.id) {
                        itemExistInWorkingList = true;
                        break;
                    }
                }
                if (!itemExistInWorkingList) 
                    deletedMilestone.add(itemInDB);
            }
            //Checking for the list size 
            if(RevRecProductRuleMilestone__c.sObjectType.getDescribe().isDeletable()){               
                if(deletedMilestone.size() > 0)
                    delete(deletedMilestone);            
            }
            
            //Loop over milestones
            for (RevRecProductRuleMilestone__c item : revRecProductRuleMilestones)  {
                
                 //Checking for product rule 
                 if(item.RevRecProductRule__c == null)
                    item.RevRecProductRule__c = overrideRule.Id;
                 
                 //Checking for MilestoneDate field value lesser then close date
                 if(theSetting.Is_Closed_Date_Validation__c) {
                 
                    if(item.Milestone_Date__c != null && item.Milestone_Date__c < theOppty.CloseDate) {
                        msg = constants.ERROR_MESSAGE_BASED_ON_DATES;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }
                 }
                 
                 if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE ) {
                    
                    if(utilHelper.yearDifference(overrideRule.Start_Date__c , overrideRule.End_Date__c) > 10) {
                        msg = constants.START_END_DATE_RANGE_EXCEED;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }
                 }else {
                    
                    //Checking for the date difference 
                    //Added on 13 sept
                    if(utilHelper.yearDifference(theOppty.CloseDate , item.Milestone_Date__c) > 10) {
                        msg = constants.START_END_DATE_RANGE_EXCEED;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }
                 }                   
            }
                       
            //Code added - 11 july 2016 - AM ISSUE
            if(!isRuleDateChangeFirstTime) {
            	
                //Checking for the list size 
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRuleMilestone__c')){
                    if(revRecProductRuleMilestones.size() > 0)
                        upsert revRecProductRuleMilestones;     
                }          
            } 
                                    
            //Code added - 06/16/2015 - As per Blended Revenue recognition
            if(overrideRule.Recognition_Type__c  == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
                //List of categories to be deleted
                List<RevRecProductRuleCategory__c> catToDelete = new List<RevRecProductRuleCategory__c>();
                
                //Set of categories to be deleted
                if(setCategoriesToBeDeleted.size() > 0) {
                    
                    //Loop over ids
                    for(Id catId : setCategoriesToBeDeleted)
                        catToDelete.add(new RevRecProductRuleCategory__c(Id = catId));
                }
               
                //Checking for list size
                if(RevRecProductRuleCategory__c.sObjectType.getDescribe().isDeletable()){
                    if(catToDelete.size() > 0)
                        delete catToDelete;
                }
                //List of Product Rule Category 
                List<RevRecProductRuleCategory__c> listProductToInsert = new List<RevRecProductRuleCategory__c>();
                
                //Variables to hold recognized and deferred amount
                Decimal recognizedAmount ;
                Decimal deferredAmount;
                Decimal actualDeferred;
                Decimal actualCatDifference = 0.00;
                Decimal outstandingBalance = oli.TotalPrice;
                msg = '';
                totalRecognized = 0.00;
                totalDeferred = 0.00; 
                totalRemainingBlended = 0.00;                                                                                                                                                                       
               
                System.debug('listCategoryWrap...@@@' + listCategoryWrap);
                System.debug('salesforceTheme...@@@' + salesforceTheme);
                //Loop through wrapper
                for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
                    if(salesforceTheme != 'Theme3') {
                        
                        if(String.isNotBlank(productCatWrapper.lightningStartDate))  {
                            productCatWrapper.lightningStartDate = productCatWrapper.lightningStartDate.trim().replace(' ' , '');
                            productCatWrapper.revRecProductCategory.Actual_Start_Date__c = Date.parse(productCatWrapper.lightningStartDate);
                        } 
                        
                        if(String.isNotBlank(productCatWrapper.lightningEndDate))  {
                            productCatWrapper.lightningEndDate = productCatWrapper.lightningEndDate.trim().replace(' ' , '');
                            productCatWrapper.revRecProductCategory.Actual_End_Date__c = Date.parse(productCatWrapper.lightningEndDate);
                        } 
                    }
                    //Checking for 
                    if(theSetting.Is_Closed_Date_Validation__c) {
                        if(productCatWrapper.revRecProductCategory.Actual_Start_Date__c!= null && productCatWrapper.revRecProductCategory.Actual_Start_Date__c < theOppty.CloseDate) {
                            msg += constants.ERROR_MESSAGE_BASED_ON_DATES;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                            return null;
                            
                        }else if(productCatWrapper.revRecProductCategory.Actual_End_Date__c != null && productCatWrapper.revRecProductCategory.Actual_End_Date__c < theOppty.CloseDate) {
                            msg += constants.ERROR_MESSAGE_BASED_ON_DATES;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                            return null;
                        }
                    }
                                      
                    //Checking for the date difference 
                    //Added on 13 sept
                    if(utilHelper.yearDifference(productCatWrapper.revRecProductCategory.Actual_Start_Date__c , productCatWrapper.revRecProductCategory.Actual_End_Date__c) > 10) {
                        msg = constants.START_END_DATE_RANGE_EXCEED;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }               
                    //Reset values
                    recognizedAmount = 0.00;
                    actualDeferred = 0.00;
                    deferredAmount = 0.00;
                    
                    //Setting app setting
                    RevRecUtil.appSetting = theSetting;
                    
                    //Calling method to calculate recognized and deferred amount    
                    wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlended(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listCategoryWrap, actualDeferred, overrideRule);
                     
                    recognizedAmount = wrapCalculation.recognizedAmount;
                    deferredAmount = wrapCalculation.deferredAmount;
                    outstandingBalance = wrapCalculation.outStandingBalance;
                    actualDeferred = wrapCalculation.actualDeferred;
                    actualCatDifference = wrapCalculation.actualCatDifference;
                    msg = wrapCalculation.msg;  
                    
                    //Set values in Product Category
                    productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
                    productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
                    productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
                    outstandingBalance = outstandingBalance - actualCatDifference;
                    
                    //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                    //If true the do this 
                    if(isMultiCurrencyEnabled) {
                        
                        if(actualDeferred != null) {
                            productCatWrapper.revRecProductCategory.Converted_Actual_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), actualDeferred)).replace('<br/>', '');
                            productCatWrapper.revRecProductCategory.Cor_Act_Def__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), actualDeferred));
                        } else {
                            productCatWrapper.revRecProductCategory.Converted_Actual_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                            productCatWrapper.revRecProductCategory.Cor_Act_Def__c = 0.00;
                        }
                        if(deferredAmount != null) {
                            productCatWrapper.revRecProductCategory.Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), deferredAmount)).replace('<br/>', '');
                            productCatWrapper.revRecProductCategory.Cor_Def_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), deferredAmount));
                        } else {
                            productCatWrapper.revRecProductCategory.Converted_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                            productCatWrapper.revRecProductCategory.Cor_Def_Amt__c = 0.00;
                        }
                        if(recognizedAmount != null) {
                            productCatWrapper.revRecProductCategory.Converted_Recognized_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), recognizedAmount)).replace('<br/>', '');
                            productCatWrapper.revRecProductCategory.Cor_Rec_Amt__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), recognizedAmount));
                        } else {
                            productCatWrapper.revRecProductCategory.Converted_Recognized_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                            productCatWrapper.revRecProductCategory.Cor_Rec_Amt__c = 0.00;
                        }
                    }
                                            
                    productCatWrapper.revRecProductCategory.RevRecProductRule__c = overrideRule.Id;
                    
                    totalRecognized += productCatWrapper.revRecProductCategory.Recognized_Amount__c;
                    totalDeferred += productCatWrapper.revRecProductCategory.Actual_Deferred__c;
                    sumOfCatRecogRev += productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
                    sumOfCatDeferRev += productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
                     
                    if(sumOfCatRecogRev-totalRecognized.setScale(2) >= 0.01) {
	                	Decimal recogAmount = productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
	                	recogAmount -= (sumOfCatRecogRev-totalRecognized);
	                	productCatWrapper.revRecProductCategory.Recognized_Amount__c = recogAmount;
	                	sumOfCatRecogRev -= (sumOfCatRecogRev-totalRecognized);
	                } else if(totalRecognized-sumOfCatRecogRev >= 0.01) {
		            	Decimal recogAmount = productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
		            	recogAmount += (totalRecognized-sumOfCatRecogRev);
		            	productCatWrapper.revRecProductCategory.Recognized_Amount__c = recogAmount;
		            	sumOfCatRecogRev += (totalRecognized-sumOfCatRecogRev);
		            }
	                if(sumOfCatDeferRev-totalDeferred.setScale(2) >= 0.01) {
	                	Decimal deferAmount = productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
	                	deferAmount -= (sumOfCatDeferRev-totalDeferred);
	                	productCatWrapper.revRecProductCategory.Actual_Deferred__c = deferAmount;
	                	sumOfCatDeferRev -= (sumOfCatDeferRev-totalDeferred);
	                } else if(totalDeferred-sumOfCatDeferRev >= 0.01) {
		            	Decimal deferAmount = productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
		            	deferAmount += (totalDeferred-sumOfCatDeferRev);
		            	productCatWrapper.revRecProductCategory.Actual_Deferred__c = deferAmount;
		            	sumOfCatDeferRev += (totalDeferred-sumOfCatDeferRev);
		            }
                    
					if((totalRecognized+totalDeferred) == lineItem.TotalPrice) {
		            	if((sumOfCatRecogRev+sumOfCatDeferRev) < (totalRecognized+totalDeferred)) {
		            		if(totalRecognized != 0.00) {
		            			if(productCatWrapper.revRecProductCategory.Recognized_Amount__c != 0.00) {
		            				productCatWrapper.revRecProductCategory.Recognized_Amount__c += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				Decimal totalRec = totalRecognized.setScale(2);
		            				totalRec += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				totalRecognized = totalRec;
		            				sumOfCatRecogRev = totalRec;
		            			}
		            		} else if(totalDeferred != 0.00) {
		            			if(productCatWrapper.revRecProductCategory.Actual_Deferred__c != 0.00) {
		            				productCatWrapper.revRecProductCategory.Actual_Deferred__c += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				Decimal totalDef = totalDeferred.setScale(2);
		            				totalDef += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				totalDeferred = totalDef;
		            				sumOfCatDeferRev = totalDef;
		            			}
		            		}
		            	} else if((sumOfCatRecogRev+sumOfCatDeferRev) > (totalRecognized+totalDeferred)) {
		            		if(totalRecognized != 0.00) {
		            			if(productCatWrapper.revRecProductCategory.Recognized_Amount__c != 0.00) {
		            				productCatWrapper.revRecProductCategory.Recognized_Amount__c -= ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				Decimal totalRec = totalRecognized.setScale(2);
		            				totalRec -= ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				totalRecognized = totalRec;
		            				sumOfCatRecogRev = totalRec;
		            			}
		            		} else if(totalDeferred != 0.00) {
		            			if(productCatWrapper.revRecProductCategory.Actual_Deferred__c != 0.00) {
		            				productCatWrapper.revRecProductCategory.Actual_Deferred__c -= ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				Decimal totalDef = totalDeferred.setScale(2);
		            				totalDef -= ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
		            				totalDeferred = totalDef;
		            				sumOfCatDeferRev = totalDef;
		            			}
		            		}
		            	}
	            	}
                    
                    //Checking if start and end date not null
                    if(productCatWrapper.revRecProductCategory.Actual_Start_Date__c != null  && productCatWrapper.revRecProductCategory.Actual_End_Date__c != null)
                        productCatWrapper.revRecProductCategory.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE;
                    
                    if(productCatWrapper.revRecProductCategory.Category_End_Date__c == 'None')
                        productCatWrapper.revRecProductCategory.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
                    
                    //Populate name
                    productCatWrapper.revRecProductCategory.Name = productCatWrapper.revRecProductCategory.Name;
                    
                    //Populate list of product category to be inserted 
                    listProductToInsert.add(productCatWrapper.revRecProductCategory);
                }
                
                if(lineItem.TotalPrice < (totalRecognized.setScale(2) + totalDeferred.setScale(2))) {
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Actual Revenue is greater than line item amount' ));
                    return null;
                }

                //Insert Category
                if(listProductToInsert.size() > 0)
                    upsert listProductToInsert;
            }
            
            if (msg != '')   {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                return null;
            } 
            
            //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
            //Remianing amount, percentage, quantity
            revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized.setScale(2) + totalDeferred.setScale(2)));
            revRecLineItem.RecognizedRev__c = totalRecognized.setScale(2);           
            revRecLineItem.DeferredRev__c = totalDeferred.setScale(2);              
			
            if(lineItem.TotalPrice > 0) {
                revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
                revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
            }else {
                revRecLineItem.Remaining_Percentage__c = 0.00;
                revRecLineItem.Remaining_Qty__c = 0.00;
            }
            //Updating revrecOpportunityLineItem instance
        	update revRecLineItem;
            
            return new PageReference('/'+ opportunityId);
         }catch(Exception e) {
            system.debug('@@@ Error msg' +e.getMessage() + e.getLineNumber());
        }
        return new PageReference('/' + opportunityId) ; 
    }   
    
    //Code modified - 04/08/2015 - As per recognized revenue calculation
    public PageReference ChangeMilestoneType() {
        
        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
            
            if (overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                                               
                    if (item.Actual_Amount__c == null && item.Actual_Qty__c != null)
                        item.Actual_Amount__c = (item.Actual_Qty__c * lineItem.TotalPrice /lineItem.quantity).setScale(2);
                    else if (item.Actual_Amount__c == null && item.Actual_Percent__c != null) 
                        item.Actual_Amount__c = (item.Actual_Percent__c * lineItem.TotalPrice /100.0).setScale(2);
                    else 
                        item.Actual_Amount__c = item.Actual_Amount__c;  
                    
                    //Projected calculation
                    if (item.Projected_Amount__c == null && item.Projected_Qty__c != null)
                        item.Projected_Amount__c = (item.Projected_Qty__c * lineItem.TotalPrice /lineItem.quantity).setScale(2);
                    else if (item.Projected_Amount__c == null && item.Projected_Percent__c != null) 
                        item.Projected_Amount__c = (item.Projected_Percent__c * lineItem.TotalPrice /100.0).setScale(2);
                    else 
                        item.Projected_Amount__c = item.Projected_Amount__c; 
                }
            } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        
                    if (item.Actual_Qty__c  == null && item.Actual_Percent__c != null) 
                        item.Actual_Qty__c = (item.Actual_Percent__c * lineItem.Quantity /100.0).setScale(2);
                    else if (item.Actual_Qty__c == null && item.Actual_Amount__c != null) 
                        item.Actual_Qty__c = (item.Actual_Amount__c * lineItem.Quantity /lineItem.TotalPrice).setScale(2);
                    else
                        item.Actual_Qty__c =  item.Actual_Qty__c;
                    
                    //Projected calculation
                    if (item.Projected_Qty__c  == null && item.Projected_Percent__c != null) 
                        item.Projected_Qty__c = (item.Projected_Percent__c * lineItem.Quantity /100.0).setScale(2);
                    else if (item.Projected_Qty__c == null && item.Projected_Amount__c != null) 
                        item.Projected_Qty__c = (item.Projected_Amount__c * lineItem.Quantity /lineItem.TotalPrice).setScale(2);
                    else
                        item.Projected_Qty__c =  item.Projected_Qty__c;
                }
            } else {
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        
                    if (item.Actual_Percent__c == null && item.Actual_Amount__c != null) {
                        
                        if(lineItem.TotalPrice == 0) 
                            item.Actual_Percent__c = 0;
                        else
                            item.Actual_Percent__c = 100 * item.Actual_Amount__c/lineItem.TotalPrice; 
                    }                     
                    else if (item.Actual_Percent__c == null && item.Actual_Qty__c != null) 
                        item.Actual_Percent__c = 100 * item.Actual_Qty__c/lineItem.quantity;
                    else
                        item.Actual_Percent__c = item.Actual_Percent__c; 
                    
                    //Projected calculation
                    if (item.Projected_Percent__c == null && item.Projected_Amount__c != null) {
                        
                        if(lineItem.TotalPrice == 0) 
                            item.Projected_Percent__c = 0;
                        else
                            item.Projected_Percent__c = 100 * item.Projected_Amount__c/lineItem.TotalPrice; 
                    }                     
                    else if (item.Projected_Percent__c == null && item.Projected_Qty__c != null) 
                        item.Projected_Percent__c = 100 * item.Projected_Qty__c/lineItem.quantity;
                    else
                        item.Projected_Percent__c = item.Projected_Percent__c;  
                }
            }
        }
        
        //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
        //Remianing amount, percentage, quantity
        revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
        
        if(lineItem.TotalPrice > 0) {
            revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
            revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
        }else {
             revRecLineItem.Remaining_Percentage__c = 0.00;
             revRecLineItem.Remaining_Qty__c  = 0.00;
        } 
        return null;
    } 
    
    /**
     *  @description    :   This method is used to call on Onchange of Amortize by options for "Amortize Milestone" Rule
     *
     *  @args           :   -
     *
     *  @return         :   void
    **/
    public void ChangeMilestoneTypeForAM() {
         
        //Checking for Rule type amortize milestone
        if (overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) { 
        	 
        	if(lineItem.TotalPrice == 0.00) {
    	 		
    	 	} else {
    	 		//If Amortize by = "Amount"
            if (overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount')) {
                
                //Loop over product rule Milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //if Qty != null then calculate amount
                    if (item.qty__c != null) {
                        item.amount__c = item.qty__c * lineItem.TotalPrice /lineItem.quantity;
                        item.Percent__c = (item.Amount__c * 100 ) / lineItem.TotalPrice;
                    }
                    
                    //If Actual Qty != null then calculate Actual amount
                    if(item.Actual_Qty__c != null) {
                        item.Actual_Amount__c = item.Actual_Qty__c * lineItem.TotalPrice /lineItem.quantity; 
                        item.Actual_Percent__c = (item.Actual_Amount__c * 100 ) / lineItem.TotalPrice;
                    }
                    
                    //If Actual Qty != null then calculate Actual amount
                    if(item.Projected_Qty__c != null) {
                        item.Projected_Amount__c = item.Projected_Qty__c * lineItem.TotalPrice /lineItem.quantity;
                        item.Projected_Percent__c = (item.Projected_Amount__c * 100 ) / lineItem.TotalPrice;
                    }
                }
            
            //If Amortize by = "Qty"
            } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                
                //Loop over product rule milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                     
                    //If amount != null then calculate qty
                    if (item.amount__c != null) {
                        if(lineItem.TotalPrice == 0) {
                            item.qty__c = 0;
                            item.Percent__c = 0;
                        } else {
                            item.qty__c = (item.amount__c * lineItem.Quantity /lineItem.TotalPrice);
                            item.Percent__c = (item.amount__c * 100) /lineItem.TotalPrice;
                        }
                        
                    }
                     //If actual amount != null then  calculate Actual qty
                    if(item.Actual_Amount__c != null) {
                        if(lineItem.TotalPrice == 0) {
                            item.Actual_Qty__c = 0;
                            item.Actual_Percent__c = 0;
                        } else {
                            item.Actual_Qty__c = (item.Actual_Amount__c * lineItem.Quantity /lineItem.TotalPrice);
                            item.Actual_Percent__c = (item.Actual_Amount__c * 100) /lineItem.TotalPrice;
                        }
                    }
                    //If Sales manual amount != null then  calculate Actual qty
                     if(item.Projected_Amount__c != null)
                         if(lineItem.TotalPrice == 0) {
                            item.Projected_Qty__c = 0;
                            item.Projected_Percent__c = 0;
                         } else {
                            item.Projected_Qty__c = (item.Projected_Amount__c * lineItem.Quantity /lineItem.TotalPrice);
                            item.Projected_Percent__c = (item.Projected_Amount__c * 100) /lineItem.TotalPrice;
                         }
                     }
                         
                } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('percent')) {
                
	                //Loop over product rule milestones
	                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
	                      
	                    //If amount != null then calculate qty
	                    if (item.amount__c != null) {
	                        if(lineItem.TotalPrice == 0) {
	                            item.qty__c = 0;
	                            item.Percent__c = 0;
	                        } else {
	                            item.qty__c = (item.amount__c * lineItem.Quantity /lineItem.TotalPrice);
	                            item.Percent__c = (item.amount__c * 100) /lineItem.TotalPrice;
	                        }
	                    }
	                     //If actual amount != null then  calculate Actual qty
	                    if(item.Actual_Amount__c != null) {
	                        if(lineItem.TotalPrice == 0) {
	                            item.Actual_Qty__c = 0;
	                            item.Actual_Percent__c = 0;
	                        } else {
	                            item.Actual_Qty__c = (item.Actual_Amount__c * lineItem.Quantity /lineItem.TotalPrice);
	                            item.Actual_Percent__c = (item.Actual_Amount__c * 100) /lineItem.TotalPrice;
	                        }
	                    }
	                    //If Sales manual amount != null then  calculate Actual qty
	                    if(item.Projected_Amount__c != null) {
	                         if(lineItem.TotalPrice == 0) {
	                            item.Projected_Qty__c = 0;
	                            item.Projected_Percent__c = 0;
	                         } else {
	                            item.Projected_Qty__c = (item.Projected_Amount__c * lineItem.Quantity /lineItem.TotalPrice);
	                            item.Projected_Percent__c = (item.Projected_Amount__c * 100) /lineItem.TotalPrice;
	                         }
	                    }
	                }  
	            }
    	 	}
    	}else if(overrideRule.Recognition_Type__c == 'Milestone') {
        
            if (overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                                               
                    if (item.Actual_Amount__c == null && item.Actual_Qty__c != null)
                        item.Actual_Amount__c = (item.Actual_Qty__c * lineItem.TotalPrice /lineItem.quantity).setScale(2);
                    else if (item.Actual_Amount__c == null && item.Actual_Percent__c != null) 
                        item.Actual_Amount__c = (item.Actual_Percent__c * lineItem.TotalPrice /100.0).setScale(2);
                    else 
                        item.Actual_Amount__c = item.Actual_Amount__c;  
                    
                    //Projected calculation
                    if (item.Projected_Amount__c == null && item.Projected_Qty__c != null)
                        item.Projected_Amount__c = (item.Projected_Qty__c * lineItem.TotalPrice /lineItem.quantity).setScale(2);
                    else if (item.Projected_Amount__c == null && item.Projected_Percent__c != null) 
                        item.Projected_Amount__c = (item.Projected_Percent__c * lineItem.TotalPrice /100.0).setScale(2);
                    else 
                        item.Projected_Amount__c = item.Projected_Amount__c; 
                }
            } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        
                    if (item.Actual_Qty__c  == null && item.Actual_Percent__c != null) 
                        item.Actual_Qty__c = (item.Actual_Percent__c * lineItem.Quantity /100.0).setScale(2);
                    else if (item.Actual_Qty__c == null && item.Actual_Amount__c != null) 
                        item.Actual_Qty__c = (item.Actual_Amount__c * lineItem.Quantity /lineItem.TotalPrice).setScale(2);
                    else
                        item.Actual_Qty__c =  item.Actual_Qty__c;
                    
                    //Projected calculation
                    if (item.Projected_Qty__c  == null && item.Projected_Percent__c != null) 
                        item.Projected_Qty__c = (item.Projected_Percent__c * lineItem.Quantity /100.0).setScale(2);
                    else if (item.Projected_Qty__c == null && item.Projected_Amount__c != null) 
                        item.Projected_Qty__c = (item.Projected_Amount__c * lineItem.Quantity /lineItem.TotalPrice).setScale(2);
                    else
                        item.Projected_Qty__c =  item.Projected_Qty__c;
                }
            } else {
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        
                    if (item.Actual_Percent__c == null && item.Actual_Amount__c != null) {
                        
                        if(lineItem.TotalPrice == 0) 
                            item.Actual_Percent__c = 0;
                        else
                            item.Actual_Percent__c = 100 * item.Actual_Amount__c/lineItem.TotalPrice; 
                    }                     
                    else if (item.Actual_Percent__c == null && item.Actual_Qty__c != null) 
                        item.Actual_Percent__c = 100 * item.Actual_Qty__c/lineItem.quantity;
                    else
                        item.Actual_Percent__c = item.Actual_Percent__c; 
                    
                    //Projected calculation
                    if (item.Projected_Percent__c == null && item.Projected_Amount__c != null) {
                        
                        if(lineItem.TotalPrice == 0) 
                            item.Projected_Percent__c = 0;
                        else
                            item.Projected_Percent__c = 100 * item.Projected_Amount__c/lineItem.TotalPrice; 
                    }                     
                    else if (item.Projected_Percent__c == null && item.Projected_Qty__c != null) 
                        item.Projected_Percent__c = 100 * item.Projected_Qty__c/lineItem.quantity;
                    else
                        item.Projected_Percent__c = item.Projected_Percent__c;  
                }
            }
    
	        //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
	        //Remianing amount, percentage, quantity
	        revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
	        
	        if(lineItem.TotalPrice > 0) {
	            revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
	            revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
	        }else {
	             revRecLineItem.Remaining_Percentage__c = 0.00;
	             revRecLineItem.Remaining_Qty__c  = 0.00;
	        } 
        }
    }
   
    //Code modified - 01/20/2015 - As per Milestone Date Automation
    //milestone total percentage or amount
    public String getMilestoneTotal() {
        
        //String for result
        string result = '';
         
        //If Rule = Milestone   
        if (overrideRule.Recognition_Type__c == 'Milestone') {
            
            //Checking for milestone type Amount
            if (overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                
                //Variables
                Decimal total = 0.00;
                Decimal totalRec = 0.00;
                
                //Loop over list of milestones 
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                   
                   //If amount != null
                    if (item.Actual_Amount__c != null )   
                        total += decimal.valueOf(Double.valueOf(item.Actual_Amount__c)).setScale(2);
                    
                    if(item.Actual_Amount__c != null  && item.MileStone_Date__c != null && item.MileStone_Date__c  <= Date.Today())
                        totalRec += decimal.valueOf(Double.valueOf(item.Actual_Amount__c)).setScale(2);
                    
                }                
                //Creating result string
                result =  'Recognized - '+totalRec +'<br/> ' + ' Deferred Balance - '+(lineItem.TotalPrice - totalRec).setScale(2);
            
            //Checking for milestone type = QTY    
            } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                
                //Variables
                Decimal total = 0;
                Decimal totalRec = 0.00;
                
                //Loop over milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                   
                   //If qty != null
                    if (item.Actual_Qty__c != null)
                        total += Decimal.valueOf(Double.valueOf(item.Actual_Qty__c)).setScale(2);
                    if(item.Actual_Qty__c != null  && item.MileStone_Date__c != null && item.MileStone_Date__c  <= Date.Today())
                        totalRec += decimal.valueOf(Double.valueOf(item.Actual_Qty__c)).setScale(2);
                }
                
                //Creating result string
                result =  'Recognized - '+totalRec +'<br/>' + 'Deferred Balance - '+( lineItem.Quantity - totalRec) ;
            } else { 
                
                //Variables
                Decimal total = 0.00;
                Decimal totalRec = 0.00;
                
                //Loop over milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //Checking for percent != null
                    if (item.Actual_Percent__c != null)
                        total += decimal.valueOf(Double.valueOf(item.Actual_Percent__c)).setScale(2);
                    if(item.Actual_Percent__c != null  && item.MileStone_Date__c != null && item.MileStone_Date__c  <= Date.Today())
                        totalRec += decimal.valueOf(Double.valueOf(item.Actual_Percent__c)).setScale(2);
                }
                
                //Creating result string
                result =  'Recognized - '+totalRec +'<br/>' + 'Deferred - '+( 100 - totalRec) ;
            }
        }
             
        //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements
        //Check for Recognition_Type__c
        if(lineItem.TotalPrice != 0.00) {
        	if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
            
	            //Check for rule is Amortize by "Amount"   
	            if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount')) {
	                //Variables
	                Decimal total = 0.00;
	                Decimal totalAmount = 0.0;
	                
	                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
	                    if (item.Actual_Amount__c != null) {
	                        total += decimal.valueOf(Double.valueOf(item.Actual_Amount__c)).setScale(2);
	                    }
	                }
	                totalAmount = decimal.valueOf(Double.valueOf(lineItem.TotalPrice)).setScale(2);
	                
	                result =  'Allocated -----' + total + '/' + totalAmount +  '-----' + ((total/totalAmount)*100).setScale(2) + '%' +'<BR/>'+ 'Remaining -----' + (lineItem.TotalPrice - total).setScale(2);
	            } else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
	                Decimal total = 0;
	                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
	                    if (item.Actual_Qty__c != null)
	                        total += decimal.valueOf(Double.valueOf(item.Actual_Qty__c));
	                }
	                	
	                result =  'Allocated -----' + total.setScale(2) + '/' + lineItem.Quantity +  '-----' + ((total/lineItem.Quantity)*100).setScale(2) + '%' +'<BR/>'+ 'Remaining -----' + (lineItem.Quantity - total).setScale(2);
	            } else {
	                Decimal total = 0;
	                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
	                    if (item.Actual_Percent__c != null)
	                        total += decimal.valueOf(Double.valueOf(item.Actual_Percent__c));
	                }
	                
	                result =  'Recognized - '+total.setScale(2) +'<br/>' + 'Deferred - '+( 100 - total.setScale(2)) ;
	            } 
	        }
        }
        return result; 
    }
    
    //Code added - 01/28/2015 - get milestone total recognized amount 
    public String getMilestoneAmountTotal() {
        
        //Variables
        string result = '';
        Decimal total = 0.00;
        
        //If Recognition type is Milestone
        if (overrideRule.Recognition_Type__c == 'Milestone') {
             
            //Lopp through milestones
            for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                
                //Checking if milestone is recognized - (milestones date is set)
                if(item.MileStone_Date__c != null && item.MileStone_Date__c <= Date.Today()) {
                    
                    //If amount is not null 
                    if (item.Actual_Amount__c != null)   
                        total += (item.Actual_Amount__c).setScale(2);
                }
            }
            result =   'Recognized - '+ total.setscale(2);
        }
        return result;
    }     
    
    /**
     *  @description    :   This metho
    **/
    public String getMilestoneDeferredAmountTotal() {
        
        //Variables         
        string result = '';
        Decimal total = 0.00;
        
        //If Recognition type is Milestone
        if (overrideRule.Recognition_Type__c == 'Milestone') {
            
            //Lopp through milestones
            for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                
                //Checking if milestone is not recognized - (milestones date is set)
                if(item.MileStone_Date__c != null && item.MileStone_Date__c > Date.Today()) {
                    
                    //If amount is not null 
                    if (item.Actual_Amount__c != null)
                        total += (item.Actual_Amount__c).setScale(2);
                }
                 //Checking if milestone is not recognized - (milestones date is notset)
                if(item.MileStone_Date__c == null && string.isNotBlank(item.MileStone_Date_Source__c)) {
                    //If amount is not null 
                    if (item.Actual_Amount__c != null)
                        total += (item.Actual_Amount__c).setScale(2);
                }
            }
            result = ' Deferred - '+(total).setScale(2) ;
        }
        return result;
    }     
    
    /**
     *  @descriotion    :   This method is used to get the total actual milestone total for "Amortize Milestone".
    **/
    //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements  
    public String getMilestoneActualTotal() {
        
        string result = '';
        
        //Check for Recognition_Type__c
        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
            
            //Varibles
             Double total = 0;
             Double tot = 0;
             Decimal totalDecimal  = 0;
             Decimal totalAmount = 0.00 ;
             
            //Checking for Amortize by = Amount
            if(overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                
                //Loop over milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){

                    //Checking for milestone date
                    if(item.Milestone_Date__c <= Date.Today()) {
                      
                        //Checking if Actual Amount not null and calculate total
                        if (item.Actual_Amount__c != null) { 
                            total += Double.valueOf(item.Actual_Amount__c);
                            totalDecimal = decimal.valueOf(total).setScale(2);
                        }
                    }
                    
                    totalAmount = totalAmount  + (item.Actual_Amount__c != null ? decimal.valueOf(Double.valueOf(item.Actual_Amount__c)).setScale(2) : 0.00);
                }
                
                //Creating result string
                result =  'Recognized -----' + totalDecimal + '(based on the setting in the APPropoz Application Settings screen)' + '<BR/>'+  + 'Deferred -----' + (totalAmount - total).setScale(2)/*decimal.valueOf(Double.valueOf(revRecLineItem.DeferredRev__c)).setScale(2)*/ + '(based on the setting in the APPropoz Application Settings screen)';
            
            //Checking for Amortize by = Qty
            } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                  
                //Loop over Milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {

                    //Checking if actul qty != null and calcualte total
                    if (item.Actual_Qty__c != null) {
                        //if(decimal.valueOf(tot).setScale(2) != revRecLineItem.RecognizedRev__c) {
                        if(item.Milestone_Date__c <= Date.Today()) {
                            if (item.Actual_Amount__c != null)
                            	tot += Double.valueOf(item.Actual_Amount__c);
                        	total += Double.valueOf(item.Actual_Qty__c);
                        }
                        //total = Double.valueOf(revRecLineItem.RecognizedRev__c);
                        totalDecimal = decimal.valueOf(total).setScale(2);
                    }
                }
                
                result =  'Recognized -----' + totalDecimal + '(based on the setting in the APPropoz Application Settings screen)' + '<BR/>'+  + 'Deferred -----' + (lineItem.Quantity - total).setScale(2) + '(based on the setting in the APPropoz Application Settings screen)';
            } else {
                  
                //Loop over Milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                    
                    //Checking if actul qty != null and calcualte total
                    if (item.Actual_Percent__c != null) {
                        //if(decimal.valueOf(tot).setScale(2) != revRecLineItem.RecognizedRev__c) {
                        if(item.Milestone_Date__c <= Date.Today()) {
                            if (item.Actual_Amount__c != null) 
                            	tot += Double.valueOf(item.Actual_Amount__c);
                            total += Double.valueOf(item.Actual_Percent__c);
                        }
                        totalDecimal = decimal.valueOf(total).setScale(2);
                    }
                }
                
                result =  'Recognized -----' + totalDecimal + '(based on the setting in the APPropoz Application Settings screen)' + '<BR/>'+  + 'Deferred -----' + decimal.valueOf(100-total).setScale(2) + '(based on the setting in the APPropoz Application Settings screen)';
            } 
        }
        
        //Return result
        return result;
    }
    
    //Code added - 01/30/2015 - As per milestone date automation - (Variance)
    //Codemodified - 02/012/2015 - Change variance calculation
    public decimal getVariance() {
        
         //String to hold result
         Decimal result = 0.00;
          
        //Code added - 01/30/2015 - Variable to hold forecaste amount and actual amount
        Decimal amortizedMilestoneForecasteAmount = 0.00;
        Decimal amortizedMilestoneActualAmount = 0.00;
        Decimal amortizedMilestoneForecasteQty = 0.00;
        Decimal amortizedMilestoneActualQty = 0.00;
        Decimal amortizedMilestoneForecastePercent = 0.00;
        Decimal amortizedMilestoneActualPercent = 0.00;
    
        //Check for Recognition_Type__c
        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
            
            //check for amortized by
            if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount')) {
                
                //Lopp throgh milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //Checking for milestone date
                    if(item.Milestone_Date__c <= Date.Today()) {
                        
                        //If amount is recognized then add into forcasred amount
                        if(item.amount__c != null && item.Actual_amount__c != null)
                            amortizedMilestoneForecasteAmount += decimal.valueOf(Double.valueOf(item.amount__c)).setScale(2);
                        
                        //actual amount
                        if(item.Actual_amount__c != null)
                            amortizedMilestoneActualAmount +=   decimal.valueOf(Double.valueOf(item.Actual_Amount__c)).setScale(2);
                    }
                }
                
                //Calculating result
                result = amortizedMilestoneActualAmount - amortizedMilestoneForecasteAmount;
            //If override rule is amortized by Qty
            }else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                
                //Loop through milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //Checking for milestone date
                    if(item.Milestone_Date__c <= Date.Today()) {
                        
                        //If qty is recognized then add into forecasted
                        if (item.qty__c != null && item.Actual_qty__c != null)
                            amortizedMilestoneForecasteQty += decimal.valueOf(Double.valueOf(item.qty__c)).setScale(2);
                        
                        //Actual qty
                        if(item.Actual_qty__c != null)
                             amortizedMilestoneActualQty +=   decimal.valueOf(Double.valueOf(item.Actual_Qty__c)).setScale(2);
                    }
                }
                
                //Calculating result
                result =  amortizedMilestoneActualQty - amortizedMilestoneForecasteQty ;
            }else {
                
                //Loop through milestones
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //Checking for milestone date
                    if(item.Milestone_Date__c <= Date.Today()) {
                        
                        //If percent is recognized then add into forecasted
                        if (item.Percent__c != null)
                            amortizedMilestoneForecastePercent += decimal.valueOf(Double.valueOf(item.Percent__c)).setScale(2);
                        
                        //Actual percent
                        if(item.Actual_Percent__c != null)
                             amortizedMilestoneActualPercent +=   decimal.valueOf(Double.valueOf(item.Actual_Percent__c)).setScale(2);
                    }
                }
                
                //Calculating result
                result =  amortizedMilestoneActualPercent - amortizedMilestoneForecastePercent ;
            }
        }
        
        //Return result
        return result;
    }
    
    //This method provide select list of all the selected start and end dates in application setting + MANUAL
    public List<SelectOption> getStartAndEndDateOptions() {
        
        //List of select options
        List<SelectOption> options = new List<SelectOption>();
        
        //Add Manual into list of options
        options.add(new SelectOption(constants.MILESTONE_DATE_MANUAL, constants.MILESTONE_DATE_MANUAL));
        
        //Temp list of string to hold all selected end dates by , seprated values
        List<String> endDateString = new List<String>();
        
        //Checking if End date not blank then add selected dates into a string
        if (theSetting.Selected_End_Date_Types__c != null)
            endDateString = theSetting.Selected_End_Date_Types__c.split(',');
        
        //Set of string for already selected options
        Set<String> setOptions = new Set<String>();
        
        //Loop through strings and add them into list of options
        for(String s: endDateString) {
            
            //Checking if map contains the string
            if (allDates.containsKey(s)) {
                options.add(new SelectOption(s,allDates.get(s)));
                setOptions.add(s);
            }
        }
        
        //Temp list of string to hold all selected start date , seprated values
        List<String> startDateString = new List<String>();
        
        //Checking if Start date not blank then add selected dates into a string
        if (theSetting.Selected_Start_Date_Types__c != null)
            startDateString = theSetting.Selected_Start_Date_Types__c.split(',');
       
        //Loop through string and add them into list of options
        for(String s: startDateString) {
            
            //Checking if map contains the string
            if (allDates.containsKey(s))
                
                if(setOptions.size() > 0) {
                    if(!setOptions.contains(s))
                        options.add(new SelectOption(s,allDates.get(s)));
                }else               
                    options.add(new SelectOption(s,allDates.get(s)));
        }
        
        //Return list of select option
        return options;
    }
    
    /**
     *  @description    : These method are used to show some values.
    **/
    public Boolean getShowTotalPeriod () { return showTotalPeriod;}
    public void setShowTotalPeriod (Boolean theValue) {showTotalPeriod = theValue; }
    public PageReference ChangeShowTotalPeriod() { return null;}
    
    /**
     *  @descrption :  This method is used to Add new milestones for milestone and Amortize milestone rule type.
    **/
    public void addMilestone () {
        
        //Checking for Amortize milestone
        if(overrideRule.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
            
            Integer currentSequence = revRecProductRuleMilestones.Size();
            revRecProductRuleMilestones.add(new RevRecProductRuleMilestone__c (Milestone_Sequence__c = currentSequence + 1, Milestone_Name__c = '', Milestone_Date_Source_Label__c = constants.MILESTONE_DATE_MANUAL,
                                                                                 Milestone_Date_Source__c = constants.MILESTONE_DATE_MANUAL));
        //In case of Milestone    
        }else {
             
            //Integer to hold the highest selected counter
            Integer highestRowCounter = 0; 
            
            //List to hold the strings in list
            List<Integer>  strings = new List<Integer>();           
            
            //Chcking for selected values
            if(string.isNotBlank(indexString)) {
                
                //Loop over Category wrapper
                for(String str : indexString.split(',')) {
                      strings.add(Integer.valueOf(str) + 1);
                }
                
                //Sort list
                strings.sort();
                
                //Get the highest counter
                highestRowCounter = strings[strings.size() - 1];
            }
            
            //If highest counter is zero, means No row selected
            if(highestRowCounter == 0)
                highestRowCounter =  revRecProductRuleMilestones.Size();
            
            //Instance of Miles
            RevRecProductRuleMilestone__c mile  = new RevRecProductRuleMilestone__c(Milestone_Sequence__c = highestRowCounter + 1, Milestone_Name__c = '', Milestone_Date_Source_Label__c = constants.MILESTONE_DATE_MANUAL,
                                                                                 Milestone_Date_Source__c = constants.MILESTONE_DATE_MANUAL);
            
            //Set counter +1 after the new row addition Milestones
            for(RevRecProductRuleMilestone__c mS : revRecProductRuleMilestones) {
                
                //Checking for next rows after new and set +1 
                if(mS.Milestone_Sequence__c > highestRowCounter) {
                    mS.Milestone_Sequence__c += 1;
                }
            }   
            //Add mile stone into list     
            revRecProductRuleMilestones.add(mile);
            
            //Map to hold RevRecRuleMilestone__c record with sequence
            Map<Integer, RevRecProductRuleMilestone__c> mapSeqWithMiles = new   Map<Integer, RevRecProductRuleMilestone__c>();
            
            //Loop over List category wrapper
            for(RevRecProductRuleMilestone__c mStone : revRecProductRuleMilestones) {
                mapSeqWithMiles.put(Integer.valueOf(mStone.Milestone_Sequence__c)  , mStone);
            }
            
            //List of Sequence
            List<Integer> listSequences = new List<Integer>();
            listSequences.addAll(mapSeqWithMiles.keySet());
            listSequences.sort();
            
            //Clear List of milestones  
            revRecProductRuleMilestones.clear();
            
            //Loop over sequences
            for(Integer seq  : listSequences) 
                revRecProductRuleMilestones.add(mapSeqWithMiles.get(seq));               
        }
    }
    
    /**
     *  @description    :   This method is used to remove milestones 
     *
     *  @args           :
     *
     *  @return         :   Void
    **/
    public void removeMilestone () {
        
        //Checking for Amortize milestone
        if(overrideRule.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
        
            Integer currentSequence = revRecProductRuleMilestones.Size();
            if (currentSequence > 0)
                revRecProductRuleMilestones.remove(currentSequence - 1 );
        }else {
            
            //Set to hold sequence AND Name
            Set<Integer> setSequences = new Set<Integer>();
            Set<String> setString = new Set<String>();
            
            //Map to hold Wrapper with sequence
            Map<Integer, RevRecProductRuleMilestone__c> mapSeqWithMiles = new Map<Integer, RevRecProductRuleMilestone__c>();
            
            //Loop over list
            for(RevRecProductRuleMilestone__c mile : revRecProductRuleMilestones) 
                mapSeqWithMiles.put(Integer.valueOf(mile.Milestone_Sequence__c), mile);
            
            //Checking for the string
            if(string.isNotBlank(indexString)) {
                 
                //Loop over wrapper class and checking for the selected record 
                for(String str : indexString.split(',')) {
                            
                    setSequences.add(Integer.valueOf(str));
                    
                    //Check is added on 8 Dec 2016
                    if(revRecProductRuleMilestones.size() > Integer.valueOf(str))
                        setString.add(revRecProductRuleMilestones[Integer.valueOf(str)].Name);
                }   
            }else {
                setSequences.add(Integer.valueOf(revRecProductRuleMilestones.size() - 1));
                setString.add(revRecProductRuleMilestones[Integer.valueOf(revRecProductRuleMilestones.size() - 1)].Name);
            }
            //Checking for current sequence size and remove sequence from series
            if (setSequences.size() > 0) {
                for(Integer seq : setSequences)
                    mapSeqWithMiles.remove(seq+1);
            }
            
            //Initlize category wrap and assign temp list to wrapper
            revRecProductRuleMilestones = new List<RevRecProductRuleMilestone__c>();
            revRecProductRuleMilestones = mapSeqWithMiles.values();
            Integer j = 1;
            
            //Loop over Category wrapper
            for(RevRecProductRuleMilestone__c mile : revRecProductRuleMilestones) {
                mile.Milestone_Sequence__c = j; 
                j++;
            }
           
            //Delete Rule category
            for(RevRecProductRuleMilestone__c miles : [Select Id From RevRecProductRuleMilestone__c WHERE Name IN: (setString) AND RevRecProductRule__c =:overrideRule.Id])
                setMilesIdToBeDeleted.add(miles.Id);                
        }
    } 
    
    //Code added - 01/30/2015 - For amortozed milestone - add rule section
    public PageReference saveMilestone() {
        try {
            //Variable
            string msg = '';
            
            //Get line item id from Url Parameter
            lineItemId =  ApexPages.currentPage().getParameters().get('opportunityLineItemId');
            
            //Query through line item
            lineItem = [SELECT Id,Name ,TotalPrice,Quantity, PricebookEntry.Name, RevRecOpportunityLineItem__r.Id,RevRecOpportunityLineItem__r.RecognizedRev__c FROM OpportunityLineItem 
                            WHERE Id = :lineItemId];
            
            //Check for null
            if(lineItem.RevRecOpportunityLineItem__r == null){
                revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name,  opportunity__c = opportunityId);
                insert(revRecLineItem);
            } else {
                revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
            }   
                        
            lineItem.RevRecOpportunityLineItem__c = revRecLineItem.id;
            
            //Code Added - 11/01/2014 - As per Amortized Milestone Rule Requirements
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                Constants.IS_BY_PASS_RULE_TRIGGER = true;
                Constants.IS_BY_PASS_TRIGGER = true;
            }
            
            update(lineItem);
            
            //Check for override rule
            if (overrideRule.RevRecOpportunityLineItem__c == null && Utility.checkFieldPermission(mapfieldProdRuleResult,'RevRecOpportunityLineItem__c',Constants.PERMISSION_UPSERT)) 
                overrideRule.RevRecOpportunityLineItem__c = revRecLineItem.Id;
            if (showTotalPeriod && Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT) && Utility.checkFieldPermission(mapfieldProdRuleResult,'Total_Period__c',Constants.PERMISSION_UPSERT))
                overrideRule.End_Date__c = null;
            else 
                overrideRule.Total_Period__c = null; 
           
            //Upsert rule
            upsert (overrideRule);
            Constants.IS_BY_PASS_RULE_TRIGGER = false;
            
           //Check if recogiinition type is Amortized milestone
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
              
                //Code added- 09/01/2015 - As per new Revview requirement
                if(theSetting.Is_Closed_Date_Validation__c) {
                    
                    if(theOppty.CloseDate > overrideRule.start_Date__c){
                        msg += constants.ERROR_MESSAGE_BASED_ON_DATES;
                            
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }
                    //Code added- 09/01/2015 - As per new Revview requirement
                    else if(theOppty.CloseDate > overrideRule.End_Date__c) {
                        msg += constants.ERROR_MESSAGE_BASED_ON_DATES;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                        return null;
                    }
                }                
                //Check if Milestone ttype is Amount
                if (overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                    
                    //variables
                    Decimal totalAmount = 0;
                    Decimal totalActualAmount = 0;
                    
                    //Loop thrugh milestoneas
                    for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        
                        //Code added - 10/29/2015
                        //Checking for milestone date less than equal today
                        if(item.Milestone_Date__c <= Date.Today()) {
                      
                            //If amont not null then calculatte else show message on page 
                            if (item.amount__c != null) {
                                totalAmount += item.Amount__c;
                                if(item.RevRecProductRule__c == null )
                                        item.RevRecProductRule__c = overrideRule.Id;                    
                            } else {
                                msg += 'Milestone amount for "' + item.Milestone_Name__c +'"  need to be defined. ';
                            }
                            
                            //If amont not null then calculatte else show message on page 
                            if (item.Actual_Amount__c != null) {
                                totalActualAmount += item.Actual_Amount__c;
                                if(item.RevRecProductRule__c == null )
                                    item.RevRecProductRule__c = overrideRule.Id;                    
                            } 
                        }
                    }
                    if ((math.floor(totalAmount) - lineItem.TotalPrice) > 2)
                        msg += 'The Total Forcasted Amount for the milestones exceeds the current product Line Item total. Please go back to the opportunity to increase Line Item amount or adjust milestone amounts.';
                     
                    if ((math.floor(totalActualAmount) - lineItem.TotalPrice) > 2)
                        msg += 'The Total actual Amount for the milestones exceeds the current product Line Item total. Please go back to the opportunity to increase Line Item amount or adjust milestone amounts.';
                } 
                       
                //Checck if mileStone type is quantity
                else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                    
                    //Variables
                    Decimal totalQty = 0;
                    Decimal totalActualQty = 0;
                    
                    //Loop through the milestones record
                    for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                        
                        //Code added - 10/29/2015
                        //Checking for milestone date less than equal today
                        if(item.Milestone_Date__c <= Date.Today()) {
                      
                            //If quantity (forcasted) not null then calculate else show message on page
                            if (item.qty__c != null) {
                                totalQty += item.qty__c;
                                if(item.RevRecProductRule__c == null )
                                    item.RevRecProductRule__c = overrideRule.Id;                    
                            } else {
                                msg += 'Milestone qty for "' + item.Milestone_Name__c +'"  need to be defined. ';
                            }
                            
                            //If quantity (Actual) not null then calculate else show message on page
                            if (item.Actual_Qty__c != null) {
                                totalActualQty += item.Actual_Qty__c;
                                if(item.RevRecProductRule__c == null )
                                    item.RevRecProductRule__c = overrideRule.Id;                    
                            }
                        }
                    }
                    
                    //Checkinh for difference
                    if ((math.floor(totalQty) - lineItem.Quantity) > .0001)
                        msg += 'The Total Qty for the milestones exceeds the current product Line Item total. Please go back to the opportunity to increase Line Item quantity or adjust milestone qty.';
                    
                    //Checkinh for difference
                    if ((math.floor(totalActualQty) - lineItem.Quantity) > .0001)
                        msg += 'The Total actual Qty for the milestones exceeds the current product Line Item total. Please go back to the opportunity to increase Line Item quantity or adjust milestone qty.';
                } 
            }
            
            //Checking for error message 
            if (msg != '')   {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                return null;
            } 
            
            //Milestones
            List<RevRecProductRuleMilestone__c> allMilestoneInDB = [SELECT Id FROM RevRecProductRuleMilestone__c WHERE RevRecProductRule__c = :overrideRule.Id];
            List<RevRecProductRuleMilestone__c> deletedMilestone = new List<RevRecProductRuleMilestone__c>();
            for(RevRecProductRuleMilestone__c itemInDB : allMilestoneInDB) {
                boolean itemExistInWorkingList = false;
                for (RevRecProductRuleMilestone__c itemInWorkingList : revRecProductRuleMilestones) {
                    if (itemInWorkingList.Id != null && itemInWorkingList.Id == itemInDB.id) {
                        itemExistInWorkingList = true;
                        break;
                    }
                }
                if (!itemExistInWorkingList) 
                    deletedMilestone.add(itemInDB);
            } 
     
            if (deletedMilestone.size() > 0)
                delete(deletedMilestone);
                
            list<RevRecProductRuleMilestone__c> productMilestoneList = new List<RevRecProductRuleMilestone__c>();
            for (RevRecProductRuleMilestone__c item : revRecProductRuleMilestones)  {
                //Code added - 11/7/2014  - As per Amortized Milestone Rule Requirements
                 if (item.Id == null) 
                     item.Name = item.MileStone_Name__c;
                                 
                //if(item.Milestone_Date__c != null) 
                productMilestoneList.add(item);
            }
            
            ///If Amortize milestone, by pass the trigger
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)             
               Constants.IS_BY_PASS_TRIGGER = true;
            
            upsert(productMilestoneList);
            
            return new PageReference('/' + opportunityId) ; 
        }catch (Exception e) {
            
        }
        return new PageReference('/' + opportunityId) ;
    }
    
    //Method to call all getter setter of controller onchange event
    public void ChangeMilestoneDateSource() {
        
        //Code added - 02/03/2015 - Calculate date from date variable
        Date mileStoneDate = null;
        
        //Loop through milestones
        for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
           
            //get the start date and end date    
            String RevRecMileStoneDateSourceField = item.Milestone_Date_Source__c;
                
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
                mileStoneDate = (Date)product2.get(fieldName);
            } else if (RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_CONTRACT_COLON)) {
                String fieldName = RevRecMileStoneDateSourceField.subString(9, RevRecMileStoneDateSourceField.length());
                mileStoneDate = (Date)contract.get(fieldName);
            } else {
                mileStoneDate = item.Milestone_Date__c;
            } 
            
            //Checking if Date source is produuct / Opportunity /   Manual  
            if ((RevRecMileStoneDateSourceField != null && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_LINE_ITEM_COLON)) 
                                || RevRecMileStoneDateSourceField != null 
                                && RevRecMileStoneDateSourceField.contains(constants.SOBJECT_OPPORTUNITY_COLON)) {
           
                //Getting field label from field Api name
                  if(allDates.containsKey(RevRecMileStoneDateSourceField)) {
                     milestoneDateSource = allDates.get(RevRecMileStoneDateSourceField);
                   }
            } else {
                milestoneDateSource = constants.MILESTONE_DATE_MANUAL;
            }
            
            //Set milestone date label
            item.Milestone_Date_Source_Label__c = milestoneDateSource;          
            
            //Set milestone date from date variable
            item.Milestone_Date__c = mileStoneDate;  
        }
    }
        
    /**
     *  @description    :   This method is used to save milestone for Milestone rule type.
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    public pageReference saveMilesOnBlur() {
        
        //Get line item id from Url Parameter
            lineItemId =  ApexPages.currentPage().getParameters().get('opportunityLineItemId');
            
            //Query through line item
            lineItem = [SELECT Id,Name ,TotalPrice,Quantity, RevRecRule__c, Rule_Assignment__c, PricebookEntry.Name, RevRecOpportunityLineItem__r.Id FROM OpportunityLineItem 
                            WHERE Id = :lineItemId];
            
            //Check for null
            if(lineItem.RevRecOpportunityLineItem__r == null){
                revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name,  opportunity__c = opportunityId);
                insert(revRecLineItem);
            } else {
                revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
            }   
                        
            lineItem.RevRecOpportunityLineItem__c = revRecLineItem.id;
            
            //Code Added - 11/01/2014 - As per Amortized Milestone Rule Requirements
            if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)
                Constants.IS_BY_PASS_TRIGGER = true;
            
            update(lineItem);
            
            //Check for override rule
            if (overrideRule.RevRecOpportunityLineItem__c == null && Utility.checkFieldPermission(mapfieldProdRuleResult,'RevRecOpportunityLineItem__c',Constants.PERMISSION_UPSERT)) 
                overrideRule.RevRecOpportunityLineItem__c = revRecLineItem.Id;
            if (showTotalPeriod && Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT) && Utility.checkFieldPermission(mapfieldProdRuleResult,'Total_Period__c',Constants.PERMISSION_UPSERT))
                overrideRule.End_Date__c = null;
            else 
                overrideRule.Total_Period__c = null;
        
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRule__c')){
            upsert overrideRule;        
        }             
        
        string msg = '';
        if (overrideRule.Recognition_Type__c == 'Milestone') {
            
            //Added on - 01/19/2015 - As per Milestone Date Automation
            Date mileStoneDate = null;
                
            if (overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                Decimal totalAmount = 0;
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    if (item.amount__c != null) {
                        totalAmount += item.Amount__c;
                        if(item.RevRecProductRule__c == null )
                            item.RevRecProductRule__c = overrideRule.Id;                    
                    } else {
                        msg += 'Milestone amount for "' + item.Milestone_Name__c +'"  need to be defined. ';
                    }
                }
            } else if (overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                Decimal totalQty = 0;
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    if (item.qty__c != null) {
                        totalQty += item.qty__c;
                        if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                    } else {
                        msg += 'Milestone qty for "' + item.Milestone_Name__c +'"  need to be defined. ';                 
                    }
                }
            } else {
                Decimal totalPercent = 0;
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    if (item.percent__c != null) {
                        totalPercent += item.Percent__c;
                        if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                    } else {
                        msg += 'Milestone percentage for "' + item.Milestone_Name__c +'"  need to be defined. ';
                    }
                }
                if ((totalPercent - 100) > 0.0001)
                    msg += 'Total percentage is over 100%';
            }    
         }
           
        if (msg != '')   {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
            return null;
        }
        
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRuleMilestone__c')){
            if(revRecProductRuleMilestones.size() >0)
                upsert revRecProductRuleMilestones;
        }
        
        return null;
    }
    
    /**
     *  @description    :   This method is used to save milestones on blur
     *
     *  @args           :   
     *
     *  @return         :   PageReference
    **/
    public pageReference saveAMMilesOnBlur() {
        
        //Get line item id from Url Parameter
        lineItemId =  ApexPages.currentPage().getParameters().get('opportunityLineItemId');
        
        //Query through line item
        lineItem = [SELECT Id,Name,TotalPrice,Quantity, Rule_Assignment__c, RevRecRule__c,PricebookEntry.Name, RevRecOpportunityLineItem__r.Id FROM OpportunityLineItem 
                        WHERE Id = :lineItemId];
        
        //Check for null
        if(lineItem.RevRecOpportunityLineItem__r == null){
            revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name,  opportunity__c = opportunityId);
            insert(revRecLineItem);
        } else {
            revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
        }   
                    
        lineItem.RevRecOpportunityLineItem__c = revRecLineItem.id;
                  
        //Code Added - 11/01/2014 - As per Amortized Milestone Rule Requirements
        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)
            Constants.IS_BY_PASS_TRIGGER = true;
        
        update(lineItem);
        
        //Check for override rule
        if (overrideRule.RevRecOpportunityLineItem__c == null && Utility.checkFieldPermission(mapfieldProdRuleResult,'RevRecOpportunityLineItem__c',Constants.PERMISSION_UPSERT)) 
            overrideRule.RevRecOpportunityLineItem__c = revRecLineItem.Id;
        if (showTotalPeriod && Utility.checkFieldPermission(mapfieldProdRuleResult,'End_Date__c',Constants.PERMISSION_UPSERT) && Utility.checkFieldPermission(mapfieldProdRuleResult,'Total_Period__c',Constants.PERMISSION_UPSERT))
            overrideRule.End_Date__c = null;
        else
            overrideRule.Total_Period__c = null; 
        
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRule__c')){
            upsert overrideRule;
        }
        
        string msg = '';
                  
       //Check if recogiinition type is Amortized milestone
        if(overrideRule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
          
            //Check if Milestone ttype is Amount
            if (overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                
                //variables
                Decimal totalAmount = 0;
                Decimal totalActualAmount = 0;
                
                //Loop thrugh milestoneas
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //Code added - 10/29/2015
                    //Checking for milestone date less than equal today
                    if(item.Milestone_Date__c <= Date.Today()) {
                          
                        //If amont not null then calculatte else show message on page 
                        if (item.amount__c != null) {
                            totalAmount += item.Amount__c;
                            if(item.RevRecProductRule__c == null )
                                    item.RevRecProductRule__c = overrideRule.Id;                    
                        } else {
                            msg += 'Milestone amount for "' + item.Milestone_Name__c +'"  need to be defined. ';
                        }
                        
                        //If amount not null then calculatte else show message on page 
                        if (item.Actual_Amount__c != null) {
                            totalActualAmount += item.Actual_Amount__c;
                            if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                        } 
                    }  
                }
            } 
                   
            //Checck if mileStone type is quantity
            else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                
                //Variables
                Decimal totalQty = 0;
                Decimal totalActualQty = 0;
                
                //Loop through the milestones record
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                    
                    //Code added - 10/29/2015
                    //Checking for milestone date less than equal today
                    if(item.Milestone_Date__c <= Date.Today()) {
                      
                        //If quantity (forcasted) not null then calculate else show message on page
                        if (item.qty__c != null) {
                            totalQty += item.qty__c;
                            if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                        } else {
                            msg += 'Milestone qty for "' + item.Milestone_Name__c +'"  need to be defined. ';
                        }
                        
                        //If quantity (Actual) not null then calculate else show message on page
                        if (item.Actual_Qty__c != null) {
                            totalActualQty += item.Actual_Qty__c;
                            if(item.RevRecProductRule__c == null )
                                item.RevRecProductRule__c = overrideRule.Id;                    
                        }
                    }
                }
            }
        }
        
        //Checking for error message and return null
        if (msg != '')   {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
            return null;
        }
        
        //Checking for list size
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRuleMilestone__c')){
            if(revRecProductRuleMilestones.size() > 0)
                upsert revRecProductRuleMilestones;
        }
        
        ///Return null
        return null;
    }
    
    /***** Code added - 06/13/2015 - as per Blended Revenue requirement *****/
    /**
     *  @description    :   This method is used for Onchange of category type
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    public pageReference ChangeCategoryType() {return null;}
    
    /**
     *  @description    :   This method is used for Onchange of category type
     *
     *  @args           :   
     *
     *  @return         :   Void
    **/
    public void ChangeCategoryTypeForSplit () {}
    
    /**
     *  @description    :   This method is used to add  row of category on  Override rule page
     *
     *  @args           :   
     *
     *  @return         :    void
    **/
    public void addCategory () {
        
        //Current sequence
        Integer currentSequence = 0;
        
         //Loop over Category wrapper
        for(ProductRuleCategoryWrapper cWrap : listCategoryWrap) {
            
            //Checking for selected category
            if(cWrap.isSelected) {
                currentSequence = 0;
                currentSequence = Integer.valueOf(cWrap.revRecProductCategory.Sequence__c);
            }   
            
            cWrap.isSelected = false;       
        }
        
        //If currenct sequence is 0 then set this to high sequence
        if(currentSequence == 0)
            currentSequence = listCategoryWrap.size();
        
        //Create a new category instance 
        RevRecProductRuleCategory__c category1 = new RevRecProductRuleCategory__c(Sequence__c = currentSequence + 1, Name = '', Category_Start_Date__c = constants.MILESTONE_DATE_MANUAL , Category_End_Date__c = 'None');
        
        //Loop over Category wrapper
        for(ProductRuleCategoryWrapper cWrap : listCategoryWrap) {
            
            if(cWrap.revRecProductCategory.Sequence__c > currentSequence) {
                
                //Assign sequence
                cWrap.revRecProductCategory.Sequence__c += 1; 
                
                //Initilize list of select option for every wrap instance
                lineItemForBlended = new List<SelectOption>();
                
                //Loop to create the line item options 
                for(Integer i=0 ; i< cWrap.revRecProductCategory.Sequence__c ; i++)
                    lineItemForBlended.add(new SelectOption(String.valueOf(i) , String.valueOf(i)));
                
                //Assign line item for blended 
                cWrap.lineItemForBlended = lineItemForBlended;
            }
        } 
        //Inilitilize list of select option
        lineItemForBlended = new List<SelectOption>();
            
        //Loop over category sequence
        for(Integer j=0 ; j<= currentSequence ; j++)
            lineItemForBlended.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
        
        listCategoryWrap.add(new ProductRuleCategoryWrapper (category1, currentSequence , lineItemForBlended, false));
        
        
        //Map to hold wrapper record with sequence
        Map<Integer, ProductRuleCategoryWrapper> mapSeqWithCatWrap = new   Map<Integer, ProductRuleCategoryWrapper>();
        
        //Loop over List category wrapper
        for(ProductRuleCategoryWrapper cWrap : listCategoryWrap) {
            mapSeqWithCatWrap.put(Integer.valueOf(cWrap.revRecProductCategory.Sequence__c)  , cWrap);
        }
        
        //List of Sequence
        List<Integer> listSequences = new List<Integer>();
        listSequences.addAll(mapSeqWithCatWrap.keySet());
        listSequences.sort();
        
        //Clear wrapper class   
        listCategoryWrap.clear();
        
        //Loop over sequences
        for(Integer seq  : listSequences) {   
            
            //Re-Populate the value         
            listCategoryWrap.add(mapSeqWithCatWrap.get(seq));
        }
    }
    
    /**
     *  @description    :   This method is used to remove row from override rule screen
     *
     *  @args           :   
     *
     *  @return     :   void
    **/
    public void removeCategory() {
        
        //Set to hold sequence
        Set<Integer> setSequences = new Set<Integer>();
        Set<String> setString = new Set<String>();
        
        //Map to hold Wrapper with sequence
        Map<Integer, ProductRuleCategoryWrapper> mapSeqWithWrap = new Map<Integer, ProductRuleCategoryWrapper>();
        
        for(ProductRuleCategoryWrapper catWrap : listCategoryWrap) 
            mapSeqWithWrap.put(Integer.valueOf(catWrap.revRecProductCategory.sequence__c), catWrap);
        
        //Loop over wrapper class and checking for the selected record 
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
            
            //Checking for Selected value
            if(productCatWrapper.isSelected) {
                setSequences.add(Integer.valueOf(productCatWrapper.revRecProductCategory.Sequence__c));
                setString.add(productCatWrapper.revRecProductCategory.Id);
            }
            
            productCatWrapper.isSelected = false;
        }      
        
        //For no any selected value 
        //Checking for the set size 
        if(setSequences.size() == 0  && setString.size() == 0) {
            
            setSequences.add(Integer.valueOf(listCategoryWrap[listCategoryWrap.size() - 1].revRecProductCategory.Sequence__c));
            
            if(listCategoryWrap[listCategoryWrap.size() - 1].revRecProductCategory.Id != null)
                setString.add(listCategoryWrap[listCategoryWrap.size() - 1].revRecProductCategory.Id);
        }
        
        //Loop over set and remove selected from the list
        if(setSequences.size() > 0) {
            
            for(Integer seq : setSequences)
                mapSeqWithWrap.remove(Integer.valueOf(seq));
        }
        
        //Initlize category wrap and assign temp list to wrapper
        listCategoryWrap = new List<ProductRuleCategoryWrapper>();
        listCategoryWrap = mapSeqWithWrap.values();
        Integer j = 0;
        
        //Loop over Category wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
            productCatWrapper.revRecProductCategory.Sequence__c = j+1; 
            productCatWrapper.rowCount = j;
            j++;
        }
        //If any value selected 
        if(setSequences.size() > 0) {
      
            //Delete Rule category
            for(RevRecProductRuleCategory__c ruleCatsToDelete : [Select Id From RevRecProductRuleCategory__c WHERE  Id IN : setString 
                                                                    AND RevRecProductRule__c =: overrideRule.Id]) {
                setCategoriesToBeDeleted.add(ruleCatsToDelete.Id);
            }
            
            //Fetching child catg to delete
            for(RevRecProductRuleCategory__c rulecChildCatsToDelete : [select id from RevRecProductRuleCategory__c where RevRecProductRule__c =: overrideRule.Id 
                                                                        AND (RevRecProductRuleSplitCategory__c IN : setString or Ultimate_Parent__c IN : setString)]) {
                
                
                  setCategoriesToBeDeleted.add(rulecChildCatsToDelete.Id);
                
            }
        }
    } 
      
    /** 
      * @description    :   Getter method  to get all start date options selected in Application setting
      *
      * @args           :
      *
      * @return         :   List<SelectOption>
    **/
    public List<SelectOption> getStartDateSelectOptions() {
        
        //List of select options
        List<SelectOption> options = new List<SelectOption>();
        
        //Add none by default
        options.add(new SelectOption(constants.MILESTONE_DATE_MANUAL, constants.MILESTONE_DATE_MANUAL));
        
        //Temp list of strings
        List<String> tempList = new List<String>();
        
        //Checking for null and populate list by spliting by ,
        if (theSetting.Selected_Start_Date_Types__c != null)
            tempList = theSetting.Selected_Start_Date_Types__c.split(',');
        
        //Loop through Temp list 
        for(String s: tempList) {
            
            //Checking if date exist in  map then add it to options
            if (allDates.containsKey(s))
                options.add(new SelectOption(s,allDates.get(s)));
        }
        
        //Return list of select options
        return options;
    }
    
    /**
      * @description    :   Getter method  to get all end date options selected in Application setting
      *
      * @args           :
      *
      * @return         :   List<SelectOption>
    **/
    public List<SelectOption> getEndDateSelectOptions() {
        
        //List of select options
        List<SelectOption> options = new List<SelectOption>();
        
        //Add none as by default
        options.add(new SelectOption('NONE', 'None'));
        options.add(new SelectOption(constants.MILESTONE_DATE_MANUAL, constants.MILESTONE_DATE_MANUAL));
        
        //Temp list of string to hold all end dates separetd by ,
        List<String> tempList = new List<String>();
        
        //Checking for null and hold into temp list
        if (theSetting.Selected_End_Date_Types__c != null)
            tempList = theSetting.Selected_End_Date_Types__c.split(',');
        
        //Loop through temp list 
        for(String s: tempList) {
            
            //Checking if date exst in map then add it to options
            if (allDates.containsKey(s))
                options.add(new SelectOption(s,allDates.get(s)));
        }
        
        //return list of select options
        return options;
    }
    
    /** Getter list to show the Recognition type on the page **/
    public List<SelectOption> getRecognitionTypeOptions() {
        
        //List of select options
        List<SelectOption> options = new List<SelectOption>();
        
        //Add values in list of select options
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION, Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION));
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_AMORTIZE, Constants.RULE_RECOGNITION_TYPE_AMORTIZE));
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_MILESTONE, Constants.RULE_RECOGNITION_TYPE_MILESTONE));
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE, Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE));
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE, Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        //return list of select options
        return options;
    }
    
    /**This method is called on change of recognition type on override screen**/
    public void ChangeRecognitionTypeOptions() {} 
    
    /**
     *  @description    :   This method is call on change of start date drop down and again calculate the recognized and deferred amount.
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public  void onChangeStartOptionsForBlended () {
        
        //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualDeferred;
        Decimal actualCatDifference = 0.00;
        Decimal outstandingBalance = oli.TotalPrice;
        String msg = '';
        totalRecognized = 0.00;
        totalDeferred = 0.00;
        totalRemainingBlended = 0.00;
        
        startRowNumber = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('startRowNum'));
        
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
            
            //Checking for rowCount
            if(startRowNumber == productCatWrapper.rowCount) {
            
                //Checking if Product category have actual date NOne and setting Recognition Type
                if(productCatWrapper.revRecProductCategory.Category_End_Date__c != 'NONE') 
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
                else 
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
                
                //Calculate Start and End Date on change of start and End Date drop down change
                productCatWrapper.revRecProductCategory = calculateStartDateFrBlendedRev(productCatWrapper.revRecProductCategory, oli, theOppty, product2, contract);
                
                //Reset values
                recognizedAmount = 0.00;
                deferredAmount = 0.00;
                actualDeferred = 0.00;
                
                //Setting app setting
                RevRecUtil.appSetting = theSetting;
                
                //Calling method to calculate recognized and deferred amount
                wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlended(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listCategoryWrap, actualDeferred, overrideRule);
                
                recognizedAmount = wrapCalculation.recognizedAmount;
                deferredAmount = wrapCalculation.deferredAmount;
                actualDeferred = wrapCalculation.actualDeferred;
                outstandingBalance = wrapCalculation.outStandingBalance;
                actualCatDifference = wrapCalculation.actualCatDifference;
                msg = wrapCalculation.msg;   
                
                //Set values in Product Category
                productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
                productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
                productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
                outstandingBalance = outstandingBalance - actualCatDifference;                 
            }
        }
        //Loop over categories
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
                
            //Calculating amount
            totalRecognized +=  (productCatWrapper.revRecProductCategory.Recognized_Amount__c) != null ? (productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2)) : 0.00;
            totalDeferred += (productCatWrapper.revRecProductCategory.Actual_Deferred__c != null ) ? ( productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2)) : 0.00;
        }
        
        //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
        //Remianing amount, percentage, quantity
        revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
        
        if(lineItem.TotalPrice > 0) {
            revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
            revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
        }else {
            revRecLineItem.Remaining_Percentage__c = 0.00;
            revRecLineItem.Remaining_Qty__c = 0.00;
        }
        //Calling calculate method
        calculateBlendedCategories();
    }
    
    /**
     *  @description    :   This method is call on change of End date drop down and again calculate the recognized and deferred amount.
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public  void onChangeEndOptionsForBlended () {
        
        //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualDeferred;
        Decimal actualCatDifference = 0.00;
        Decimal outstandingBalance = oli.TotalPrice;
        String msg = '';
        totalRecognized = 0.00;
        totalDeferred = 0.00;
        totalRemainingBlended = 0.00;
        Decimal sumOfCatRecogRev = 0.00;   //----------------
        Decimal sumOfCatDeferRev = 0.00;   //----------------
        
        //Getting end row number from parameters 
        endRowNumber = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('endRowNumber'));
        
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
            
            //Checking for rowCount
            if(endRowNumber == productCatWrapper.rowCount) {
                            
                            
                //Checking if Product category have actual date NOne and setting Recognition Type
                if(productCatWrapper.revRecProductCategory.Category_End_Date__c != 'NONE') 
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
                else 
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
                
                //Calculate Start and End Date on change of start and End Date drop down change
                productCatWrapper.revRecProductCategory = calculateEndDateFrBlendedRev(productCatWrapper.revRecProductCategory, oli, theOppty, product2, contract);
                
                //Reset values
                recognizedAmount = 0.00;
                deferredAmount = 0.00;
                actualDeferred = 0.00;
                
                 //Setting app setting
                RevRecUtil.appSetting = theSetting;
                
                //Calling method to calculate recognized and deferred amount
                wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlended(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listCategoryWrap, actualDeferred, overrideRule);
                
                recognizedAmount = wrapCalculation.recognizedAmount;
                deferredAmount = wrapCalculation.deferredAmount;
                actualDeferred = wrapCalculation.actualDeferred;
                outstandingBalance = wrapCalculation.outStandingBalance;
                actualCatDifference = wrapCalculation.actualCatDifference;
                msg = wrapCalculation.msg;   
                
                //Set values in Product Category
                productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
                productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
                productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
                outstandingBalance = outstandingBalance - actualCatDifference;                 
            }
        }
        //Loop over categories
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
                
            totalRecognized += (productCatWrapper.revRecProductCategory.Recognized_Amount__c != null ) ? (productCatWrapper.revRecProductCategory.Recognized_Amount__c) : 0.00;
            totalDeferred += (productCatWrapper.revRecProductCategory.Actual_Deferred__c != null) ? (productCatWrapper.revRecProductCategory.Actual_Deferred__c) : 0.00;
        }
        
        //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
        //Remianing amount, percentage, quantity
        revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
        
        if(lineItem.TotalPrice > 0) {
            revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
            revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
        }else {
            revRecLineItem.Remaining_Percentage__c = 0.00;
            revRecLineItem.Remaining_Qty__c  = 0.00;
        }
        //Calling calculate method
        calculateBlendedCategories();
    }
    
    /**
     *  @description    :   This method is call on change of "OfLine item" number and again calculate the deferred and recognized amount.
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public  void onChangeLineItemForBlended () {
        
        //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualDeferred;
        Decimal actualCatDifference = 0.00;
        Decimal outstandingBalance = oli.TotalPrice;
        String msg = '';
        totalRecognized = 0.00;
        totalDeferred = 0.00;
        totalRemainingBlended = 0.00;
        
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
            
            //Seetting Recognition Type
            productCatWrapper.revRecProductCategory.Line_Item__c = String.valueOf(lineItemNumber);
            
            //Reset values
            recognizedAmount = 0.00;
            deferredAmount = 0.00;
            actualDeferred = 0.00;
            
             //Setting app setting
             RevRecUtil.appSetting = theSetting;
            
            //Calling method to calculate recognized and deferred amount
            wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlended(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listCategoryWrap, actualDeferred, overrideRule);
            
            recognizedAmount = wrapCalculation.recognizedAmount;
            deferredAmount = wrapCalculation.deferredAmount;
            actualDeferred = wrapCalculation.actualDeferred;
            outstandingBalance = wrapCalculation.outStandingBalance;
            actualCatDifference = wrapCalculation.actualCatDifference;
            msg = wrapCalculation.msg;   
            
            //Set values in Product Category
            productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
            productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
            productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
            outstandingBalance = outstandingBalance - actualCatDifference; 
            
            totalRecognized += productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
            totalDeferred += productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
        }
        
        //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
        //Remianing amount, percentage, quantity
        revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
        
        if(lineItem.TotalPrice > 0) {
            revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
            revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
        }else {
               revRecLineItem.Remaining_Percentage__c  = 0.00;
               revRecLineItem.Remaining_Qty__c = 0.00;
        }
         //Calling calculate method
         calculateBlendedCategories();  
    }
        
    /**   Wrapper class for Override rule  **/
    public class ProductRuleCategoryWrapper {
         
        //Variables 
        public RevRecProductRuleCategory__c revRecProductCategory {get ; set;}
        public integer rowCount{get;set;}
        public List<SelectOption> lineItemForBlended {get;set;}
        public boolean isSelected {get;set;}
        public String lightningStartDate {get;set;}
        public String lightningEndDate {get;set;}
        
        //Constructer
        public ProductRuleCategoryWrapper(RevRecProductRuleCategory__c revRecProductCategory, integer rowCount, List<SelectOption> lineItemForBlended, Boolean isSelected) {
                                                
            //Initilization
            this.revRecProductCategory = revRecProductCategory;  
            this.rowCount = rowCount;   
            this.lineItemForBlended = lineItemForBlended;   
            this.isSelected = isSelected;
            
            if(revRecProductCategory.Actual_Start_Date__c != null)
                lightningStartDate = formatDate(revRecProductCategory.Actual_Start_Date__c);
            else
                lightningStartDate = '';
            
            lightningEndDate = '';
            
            if(revRecProductCategory.Actual_End_Date__c != null)
                lightningEndDate = formatDate(revRecProductCategory.Actual_End_Date__c);
          
        }
    }
     
    /** 
     *  @description        :   Method to calculate Actual Start Date for blended revenue recognition
     *
     *  @return             :   RevRecProductRuleCategory__c    
     *
     *  @args               :   RevRecProductRuleCategory__c revRecProductRuleCategory ,  OpportunityLineItem oli, Opportunity theOppty
    **/
    public static RevRecProductRuleCategory__c calculateStartDateFrBlendedRev (RevRecProductRuleCategory__c item,
                                                        OpportunityLineItem oli, Opportunity theOppty, Product2 product2, Contract contract) {
        
             
        //Set  dates to null default
        Date actualStartDate = null;
           
        //get the start date and end date    
        String RevRecStartDate = item.Category_Start_Date__c; System.debug('RevRecStartDate -->' +RevRecStartDate);
                                
        //Checking if start date not null and Conatins Opportunity , product or Blank
        if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_OPPORTUNITY)){
            if(RevRecStartDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                string fieldName = RevRecStartDate.subString(20, RevRecStartDate.length()); 
                actualStartDate = (Date)oli.get(fieldName);
            }
            else {
                string fieldName = RevRecStartDate.subString(12, RevRecStartDate.length()); 
                actualStartDate = (Date)theOppty.get(fieldName);
            }
        } else if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            string fieldName = RevRecStartDate.subString(8, RevRecStartDate.length());
            actualStartDate = (Date)product2.get(fieldName);
        } else if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_CONTRACT_COLON)) {
            string fieldName = RevRecStartDate.subString(9, RevRecStartDate.length());
            actualStartDate = (Date)contract.get(fieldName);
        } else if(RevRecStartDate != null && RevRecStartDate.equalsIgnoreCase(constants.MILESTONE_DATE_MANUAL)) {
            actualStartDate = item.Actual_Start_Date__c != null ? item.Actual_Start_Date__c : null;
        }  else if(RevRecStartDate != null && RevRecStartDate.equalsIgnoreCase('NONE')) {
            actualStartDate = null;
        }
      
        //Set Date from variables
        item.Actual_Start_Date__c =  actualStartDate;
 
        return item;
    }
    /** 
     *  @description        :   Method to calculate Actual  End Date for blended revenue recognition
     *
     *  @return             :   RevRecProductRuleCategory__c    
     *
     *  @args               :   RevRecProductRuleCategory__c revRecProductRuleCategory ,  OpportunityLineItem oli, Opportunity theOppty
    **/
    public static RevRecProductRuleCategory__c calculateEndDateFrBlendedRev (RevRecProductRuleCategory__c item,
                                                        OpportunityLineItem oli, Opportunity theOppty, Product2 product2, Contract contract) {
        
        //Set  dates to null default
        Date actualEndDate = null;
           
        //get the start date and end date    
        String RevRecEndDate = item.Category_End_Date__c;
         
        //Checking if end date not null and Conatins Opportunity , product or Blank
        if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_OPPORTUNITY)){
            if(RevRecEndDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
                string fieldName = RevRecEndDate.subString(20, RevRecEndDate.length()); 
                actualEndDate = (Date)oli.get(fieldName);
            }
            else {
                 string fieldName = RevRecEndDate.subString(12, RevRecEndDate.length()); 
                actualEndDate = (Date)theOppty.get(fieldName);
            }
        } else if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            string fieldName = RevRecEndDate.subString(8, RevRecEndDate.length());
            actualEndDate = (Date)product2.get(fieldName);
        } else if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_CONTRACT_COLON)) {
            string fieldName = RevRecEndDate.subString(9, RevRecEndDate.length());
            actualEndDate = (Date)contract.get(fieldName);
        } else if(RevRecEndDate != null && RevRecEndDate.equalsIgnoreCase(constants.MILESTONE_DATE_MANUAL)) {
            actualEndDate = item.Actual_End_Date__c != null ?  item.Actual_End_Date__c : null;
        }  else if(RevRecEndDate != null && RevRecEndDate.equalsIgnoreCase('NONE')) {
            actualEndDate =  null;
        }  
      
        //Set Date from variables
        item.Actual_End_Date__c = actualEndDate;
 
        return item;
    }
    
    /************* ************ Split Functionality Start************* ************/
    public void blankMethod(){
        
        //Checking for parent window and set some attribiute 
        if(screenNum == 1 || screenNum == 2 ) {
            
            listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Ultimate_Parent__c = listCategoryWrap[Integer.valueOf(categoryToBeSplit) - 1].revRecProductCategory.Id;
            listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Is_Split__c = true;
        }
    }
    
    /**
     *  @description    :   This method is used to calculate the splits according to data.
     *
     *  @args           :   -
     *
     *  @return         :   Void
    **/
    public void calculateSplit() {
        
        //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualDeferred;
        Decimal amountToSplit = originalLineItemAmount;
        Decimal qtyToSplit = originalLineItemQty;
        Decimal outstandingBalance = originalLineItemAmount;
        String msg = '';
        totalSplitRecognized = 0.00;
        totalSplitDeferred = 0.00;
        Decimal actualCatDifference = 0.00;
       
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listSplitCategoryWrap) {
            
            //Checking if Product category have actual date NOne
            if(productCatWrapper.revRecProductCategory.Category_End_Date__c != 'NONE') 
                productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
            else 
                productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
            
            //Reset values 
            recognizedAmount = 0.00; 
            deferredAmount = 0.00;
            actualDeferred = 0.00;
            
             //Setting app setting
            RevRecUtil.appSetting = theSetting;
            
            //Calling method to calculate recognized and deferred amount
            wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlendedSplit(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listSplitCategoryWrap, actualDeferred, amountToSplit, qtyToSplit, overrideRule);
           
            recognizedAmount = wrapCalculation.recognizedAmount;
            deferredAmount = wrapCalculation.deferredAmount;
            actualDeferred = wrapCalculation.actualDeferred;
            outstandingBalance = wrapCalculation.outStandingBalance;
            actualCatDifference  = wrapCalculation.actualCatDifference;
            msg = wrapCalculation.msg;   
            
            //Set values in Product Category
            productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
            productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
            productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
            outstandingBalance = outstandingBalance - actualCatDifference; 
            
            //Total recognied and deferred amount
            totalSplitRecognized += productCatWrapper.revRecProductCategory.Recognized_Amount__c;
            totalSplitDeferred += productCatWrapper.revRecProductCategory.Actual_Deferred__c;
            
            //Remaining values
            remainingSplitAmount = (originalLineItemAmount - (totalSplitDeferred + totalSplitRecognized)).setScale(2);
            
            if(originalLineItemAmount > 0) {
                remainingSplitQty  = ((remainingSplitAmount) * (originalLineItemQty/originalLineItemAmount)).setScale(3);
                remainingSplitPercent = (((remainingSplitAmount) / (originalLineItemAmount))* 100 ).setScale(2) ;
            }
        }      
    }
    
    //Code added  - 09/24/2015 - As per to add split functionality in the blended Rule type
    //Code modified - 11/17/2015 - As per to enable split button for all conditions
    public void doSplitCategories () {
        
        //Set flag
        ShowSplitBlendedRevenueRecognitionDetail = true;
            
        //List of select options 
        List<SelectOption> options = new List<SelectOption>();
        
        //Checking for null
        if(overrideRule.Id == null) {
            
            //Getting line item id
            lineItemId =  ApexPages.currentPage().getParameters().get('opportunityLineItemId');
            
            //Line item
            lineItem = [SELECT Id, Name ,TotalPrice,Quantity, PricebookEntry.Name, RevRecOpportunityLineItem__r.Id, Rule_Assignment__c, RevRecRule__c,
                         RevRecOpportunityLineItem__r.Remaining_Qty__c,
                         RevRecOpportunityLineItem__r.Remaining_Amount__c,
                         RevRecOpportunityLineItem__r.Remaining_Percentage__c
                        FROM OpportunityLineItem  WHERE Id = :lineItemId];
            
            //Checking for null
            if(lineItem.RevRecOpportunityLineItem__r == null) {
                revRecLineItem = new RevRecOpportunityLineItem__c(name=lineItem.PricebookEntry.Name,  opportunity__c = opportunityId);
                insert(revRecLineItem);
            } else 
                revRecLineItem = lineItem.RevRecOpportunityLineItem__r;
            
            //Update line item
            lineItem.RevRecOpportunityLineItem__c = revRecLineItem.id;
            update(lineItem);
            
            //Assign revrecline item to override rule
            if(Utility.checkFieldPermission(mapfieldProdRuleResult,'RevRecOpportunityLineItem__c',Constants.PERMISSION_UPSERT))
            overrideRule.RevRecOpportunityLineItem__c = revRecLineItem.Id;
            
            //Insert rule
            if(Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecProductRule__c')){
                insert overrideRule;
            }
        }
        
        //Loop over list of parent wrapper
        for(ProductRuleCategoryWrapper parentWrap : listCategoryWrap) {
            
            //Checking for ID null and ids into set
            if(parentWrap.revRecProductCategory.Id != null)
                setParentScreenCategoryIds.add(parentWrap.revRecProductCategory.Id);
        }
    
        //Checking for Window either parent or Child
        if(typeOfCategoryScreen == constants.SPLIT_SCREEN_TYPE_PARENT) {
            
            //Set screen to 1
            screenNum = 1;
            
            //Initilize value
            listSplitCategoryWrap = new List<ProductRuleCategoryWrapper>();
            categoryToBeSplitParent = categoryToBeSplit;
            
            //Temp list to be inserted'
            List<RevRecProductRuleCategory__c> tempParentListToInserted = new List<RevRecProductRuleCategory__c>();
            
            //Loop over list of parent wrapper
            for(ProductRuleCategoryWrapper parentWrap : listCategoryWrap) { 
                
                //Checking for null
                if(parentWrap.revRecProductCategory.Id == null) {
                    if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'RevRecProductRule__c',Constants.PERMISSION_CREATE))
                        parentWrap.revRecProductCategory.RevRecProductRule__c = overrideRule.Id;
                    if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleCategory__c'))
                        tempParentListToInserted.add(parentWrap.revRecProductCategory);
                }
            }
            
            //Checking for list size
            if(Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecProductRuleCategory__c')){
                if(tempParentListToInserted.size() > 0)
                    insert tempParentListToInserted;
            }
            
            //Splitted Category     
            RevRecProductRuleCategory__c splittedCategories = listCategoryWrap[Integer.valueOf(categoryToBeSplit) - 1].revRecProductCategory;
            
            //Loop over list of parent wrapper
            for(ProductRuleCategoryWrapper parentWrap : listCategoryWrap) { 
                
                //Checking for null
                if(parentWrap.revRecProductCategory.Id != null)
                    setParentScreenCategoryIds.add(parentWrap.revRecProductCategory.Id);
            }
                    
            //Instance 
            RevRecProductRuleCategory__c splittedCategories1 = new RevRecProductRuleCategory__c();
            
            //Assign Split Categories values to new instance
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Name',Constants.PERMISSION_UPSERT))
                splittedCategories1.Name = splittedCategories.Name;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Line_Item__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Line_Item__c = splittedCategories.Line_Item__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Actual_Deferred__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Actual_Deferred__c = splittedCategories.Actual_Deferred__c != null ? splittedCategories.Actual_Deferred__c : 0.00;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Actual_End_Date__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Actual_End_Date__c = splittedCategories.Actual_End_Date__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Actual_Start_Date__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Actual_Start_Date__c = splittedCategories.Actual_Start_Date__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Amount__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Amount__c = splittedCategories.Amount__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Projected_Amount__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Projected_Amount__c = splittedCategories.Projected_Amount__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Category_End_Date__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Category_End_Date__c = splittedCategories.Category_End_Date__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Category_Start_Date__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Category_Start_Date__c = splittedCategories.Category_Start_Date__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Category_Type__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Category_Type__c = splittedCategories.Category_Type__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Deferred_Amount__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Deferred_Amount__c = splittedCategories.Deferred_Amount__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Percent__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Percent__c = splittedCategories.Percent__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Projected_Qty__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Projected_Qty__c = splittedCategories.Qty__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Projected_Percent__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Projected_Percent__c = splittedCategories.Projected_Percent__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Qty__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Qty__c = splittedCategories.Projected_Qty__c;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Recognized_Amount__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Recognized_Amount__c = splittedCategories.Recognized_Amount__c != null ? splittedCategories.Recognized_Amount__c : 0.00;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'RevRecProductRuleSplitCategory__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.RevRecProductRuleSplitCategory__c = splittedCategories.Id;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'RevRecProductRule__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.RevRecProductRule__c = overrideRule.Id;
            if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Sub_Category_support__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Sub_Category_support__c = splittedCategories.Sub_Category_support__c;
            
            //Calculate Amount and quantity for the split sscreen
            originalLineItemAmount = ((splittedCategories1.Recognized_Amount__c != null ? splittedCategories1.Recognized_Amount__c : 0.00) 
                                        + (splittedCategories1.Actual_Deferred__c != null ? splittedCategories1.Actual_Deferred__c : 0.00)).setScale(2);
                                        
            originalLineItemQty =   (((splittedCategories1.Recognized_Amount__c != null ? splittedCategories1.Recognized_Amount__c : 0.00) 
                                        + (splittedCategories1.Actual_Deferred__c != null ? splittedCategories1.Actual_Deferred__c : 0.00)) 
                                        /(oli.TotalPrice) ).setScale(3);
            
            totalSplitRecognized = splittedCategories1.Recognized_Amount__c;
            totalSplitDeferred =   splittedCategories1.Actual_Deferred__c;
            lineItemRow = String.ValueOf(splittedCategories.Sequence__c);
            
            //Query to get the splitted Categories if any categories exist for main Category
            List<RevRecProductRuleCategory__c> splitCatgs = [Select Id, Name, Is_Split__c ,Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                        Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Ultimate_Parent__c,
                                                                        Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,
                                                                        RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,
                                                                        Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                                                        RevRecProductRuleSplitCategory__r.Recognized_Amount__c,Sub_Category_support__c,
                                                                        RevRecProductRuleSplitCategory__r.Ultimate_Parent__c From RevRecProductRuleCategory__c
                                                                        Where RevRecProductRuleSplitCategory__c =: splittedCategories.Id];
            
            //Checking if no any existig split exist
            if(splitCatgs.size() == 0) {
                
                //Initilize 
                options.add(new SelectOption('0', '0'));
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'sequence__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.sequence__c = 1;
                            
                //Add values in wrapper list
                listSplitCategoryWrap.add(new ProductRuleCategoryWrapper(splittedCategories1, Integer.valueOf(splittedCategories1.sequence__c), options, false));
            }else {
                
                //Re-initilize 
                totalSplitRecognized = 0.00;
                totalSplitDeferred = 0.00;
                
                //Loop over existing categories
                for(RevRecProductRuleCategory__c prdCategory : splitCatgs) {
                    
                    //Initilize list of select options
                    options = new List<SelectOption>();
                    
                    //Roll up the data
                    totalSplitRecognized += prdCategory.Recognized_Amount__c != null ? prdCategory.Recognized_Amount__c : 0.00 ;
                    totalSplitDeferred +=   prdCategory.Actual_Deferred__c != null ? prdCategory.Actual_Deferred__c : 0.00;
                    
                    //Loop over category sequence
                    for(Integer j=0 ; j< prdCategory.Sequence__c ; j++)
                        options.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
                    
                    //Populate Category wrapper 
                    listSplitCategoryWrap.add(new ProductRuleCategoryWrapper(prdCategory, Integer.valueOf(prdCategory.Sequence__c), options, false));
                }
            }   
        }else if(typeOfCategoryScreen == constants.SPLIT_SCREEN_TYPE_CHILD) { //If Split clicked from Child pop up window
            
            //Increse counter
            screenNum = screenNum+1;
            
            //Temp list of categories to be inserted
            List<RevRecProductRuleCategory__c> tempListToInserted = new List<RevRecProductRuleCategory__c>();
            
            for(ProductRuleCategoryWrapper cWrp : listSplitCategoryWrap) {
                
                if(cWrp.revRecProductCategory.Id == null) {
                    cWrp.revRecProductCategory.RevRecProductRule__c = overrideRule.Id;
                    cWrp.revRecProductCategory.RevRecProductRuleSplitCategory__c = Id.valueOf(categoryParentId);
                    
                    tempListToInserted.add(cWrp.revRecProductCategory);
                }
            }
               
            //Checking for list size
            if(tempListToInserted.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecProductRuleCategory__c'))) {
                insert tempListToInserted;
                
                //Query over Product Categories
                for(RevRecProductRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                            Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c, Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                                                            Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Sub_Category_support__c,
                                                                            RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,RevRecProductRuleSplitCategory__r.Ultimate_Parent__c,
                                                                            (Select Id, Ultimate_Parent__c,Is_Split__c , Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                            Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c, Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                                                            Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Sub_Category_support__c,
                                                                            RevRecProductRule__c, RevRecProductRuleSplitCategory__c, RevRecProductRuleSplitCategory__r.Ultimate_Parent__c, Sequence__c From RevRecProductRuleSplitCategorys__r 
                                                                            ORDER BY Sequence__c) FROM RevRecProductRuleCategory__c
                                                                            Where RevRecProductRule__c =: overrideRule.Id ORDER BY CreatedDate ASC]) {
                    
                    //Checking for size of child //Populate map with values
                    if(revCategory.RevRecProductRuleSplitCategorys__r.Size() > 0) 
                        mapParentIdWithListOfSplits.put(revCategory.Id, revCategory.RevRecProductRuleSplitCategorys__r);
                } 
            }
                
            //Save splits
            saveSplits();
            
            //Re-initilize list
            listSplitCategoryWrap =  new List<ProductRuleCategoryWrapper>();
            
            //Checking for null
            if(mapParentIdWithListOfSplits != null && mapParentIdWithListOfSplits.containsKey(categoryParentId)) {
                
                //ferching relareted split
                List<RevRecProductRuleCategory__c> productRuleCategories = mapParentIdWithListOfSplits.get(categoryParentId);
                
                //Initilize
                listSplitCategoryWrap = new List<ProductRuleCategoryWrapper>();
                
                //Splitted Category     
                RevRecProductRuleCategory__c splittedCategories = productRuleCategories[Integer.valueOf(categoryToBeSplit) - 1];
                RevRecProductRuleCategory__c splittedCategories1 = new RevRecProductRuleCategory__c();
                
                //Assign Split Categories values to new instance
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Name',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Name = splittedCategories.Name;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Line_Item__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Line_Item__c = splittedCategories.Line_Item__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Actual_Deferred__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Actual_Deferred__c = splittedCategories.Actual_Deferred__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Actual_End_Date__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Actual_End_Date__c = splittedCategories.Actual_End_Date__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Actual_Start_Date__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Actual_Start_Date__c = splittedCategories.Actual_Start_Date__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Amount__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Amount__c = splittedCategories.Amount__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Category_End_Date__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Category_End_Date__c = splittedCategories.Category_End_Date__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Category_Start_Date__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Category_Start_Date__c = splittedCategories.Category_Start_Date__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Category_Type__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Category_Type__c = splittedCategories.Category_Type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Deferred_Amount__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Deferred_Amount__c = splittedCategories.Deferred_Amount__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Percent__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Percent__c = splittedCategories.Percent__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Qty__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Qty__c = splittedCategories.Qty__c;
                //splittedCategories1.Recognition_Type__c = splittedCategories.Recognition_Type__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Recognized_Amount__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Recognized_Amount__c = splittedCategories.Recognized_Amount__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'RevRecProductRuleSplitCategory__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.RevRecProductRuleSplitCategory__c = splittedCategories.Id;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'RevRecProductRule__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.RevRecProductRule__c = overrideRule.Id;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Ultimate_Parent__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Ultimate_Parent__c = splittedCategories.Ultimate_Parent__c;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Sub_Category_support__c',Constants.PERMISSION_UPSERT))
                    splittedCategories1.Sub_Category_support__c = splittedCategories.Sub_Category_support__c;
                
                //Calculate Amount and quantity for the split sscreen
                
                if(originalLineItemAmount > 0)
                    originalLineItemQty = ((originalLineItemQty * (((splittedCategories1.Recognized_Amount__c != null ? splittedCategories1.Recognized_Amount__c : 0.00 )  + (splittedCategories1.Actual_Deferred__c != null ? splittedCategories1.Actual_Deferred__c : 0.00))) ) / (originalLineItemAmount)).setScale(3) ;
                originalLineItemAmount = ((splittedCategories1.Recognized_Amount__c != null ? splittedCategories1.Recognized_Amount__c : 0.00 )  + (splittedCategories1.Actual_Deferred__c != null ? splittedCategories1.Actual_Deferred__c : 0.00)).setScale(2);
                totalSplitRecognized = splittedCategories1.Recognized_Amount__c;
                totalSplitDeferred =   splittedCategories1.Actual_Deferred__c;
                lineItemRow = String.ValueOf(splittedCategories.Sequence__c);
                
                //Query to get the splitted Categories if any categories exist for main Category
                List<RevRecProductRuleCategory__c> splitCatgs = [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                        Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Ultimate_Parent__c,
                                                                        Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,
                                                                        RevRecProductRule__c, RevRecProductRuleSplitCategory__c,Sub_Category_support__c,
                                                                        RevRecProductRuleSplitCategory__r.Recognized_Amount__c, Projected_Amount__c, Projected_Percent__c, Projected_Qty__c,
                                                                        Sequence__c,RevRecProductRuleSplitCategory__r.Name
                                                                        From RevRecProductRuleCategory__c 
                                                                        Where RevRecProductRuleSplitCategory__c =: splittedCategories.Id];
                
                //Checking if no any existig split exist
                if(splitCatgs.size() == 0) {
                    
                    //Initilize value
                    listSplitCategoryWrap = new List<ProductRuleCategoryWrapper>();
                    
                    //Initilize 
                    options.add(new SelectOption('0', '0'));
                    if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'sequence__c',Constants.PERMISSION_UPSERT))
                        splittedCategories1.sequence__c = 1;
                                
                    //Add values in wrapper list
                    listSplitCategoryWrap.add(new ProductRuleCategoryWrapper(splittedCategories1, Integer.valueOf(splittedCategories1.sequence__c), options, false));
                }else {
                    
                    //Re-initilize
                    totalSplitRecognized = 0.00;
                    totalSplitDeferred = 0.00;
                    
                    //Loop over existing categories
                    for(RevRecProductRuleCategory__c prdCategory : splitCatgs) {
                        
                        //Initilze value
                        options = new List<SelectOption>();
                        
                        //Roll up the data
                        totalSplitRecognized += prdCategory.Recognized_Amount__c != null ? prdCategory.Recognized_Amount__c : 0.00 ;
                        totalSplitDeferred +=   prdCategory.Actual_Deferred__c != null ? prdCategory.Actual_Deferred__c : 0.00;
                        
                        //Loop over category sequence
                        for(Integer j=0 ; j< prdCategory.Sequence__c ; j++)
                            options.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
                        
                        //Populate Category wrapper 
                        listSplitCategoryWrap.add(new ProductRuleCategoryWrapper(prdCategory, Integer.valueOf(prdCategory.Sequence__c), options, false));
                    }
                }   
            }       
        }
        
        //Calculating remaining amount/qty/percent
        remainingSplitAmount = (originalLineItemAmount != null ? originalLineItemAmount : 0.00) - ((totalSplitDeferred != null ? totalSplitDeferred : 0.00)
                                + (totalSplitRecognized != null ? totalSplitRecognized : 0.00)).setScale(2);
        
        //Checking for Divider > 0
        if(originalLineItemAmount > 0)
            remainingSplitQty  = ((remainingSplitAmount) * (originalLineItemQty/originalLineItemAmount)).setScale(3);
        
        //Checking for Divider > 0
        if(originalLineItemAmount > 0)
            remainingSplitPercent = (((remainingSplitAmount) / (originalLineItemAmount))* 100 ).setScale(2) ;
    }
    /**
     *  @description    :   This method is used to save the splits for caegoories
     *
     *  @args           :   
     *
     *  @return         :   PageReference(NULL)
    **/
    public void saveSplits() {
        
        //Calculate the splits and then do further processing
        calculateSplit(); 
        
        //Variables
        Decimal deferredAmount = 0.00;
        Decimal recognizedAmount = 0.00;
        Decimal totalSplitAmountTemp = 0.00;
        Decimal actualDeferred = 0.00;
        totalSplitRecognized = 0.00;
        totalSplitDeferred = 0.00;
        Id ultimateParent ;
        
        //Set to hold ids
        Set<Id> setCATIds = new Set<Id> ();
        
        //List of categories to be deleted
        List<RevRecProductRuleCategory__c> catToDelete = new List<RevRecProductRuleCategory__c>();
        
        //Set of categories to be deleted
        if(setSplitCategoriesToBeDeleted.size() > 0) {
            
            //Loop over ids
            for(Id catId : setSplitCategoriesToBeDeleted) {
                catToDelete.add(new RevRecProductRuleCategory__c(Id = catId));
            }
        }
        
        //Checking for list size
        if(catToDelete.size() > 0 && (RevRecProductRuleCategory__c.sObjectType.getDescribe().isDeletable()))
            delete catToDelete;
        
        //List to be upserted
        List<RevRecProductRuleCategory__c> listSplitsToBeUpserted = new List<RevRecProductRuleCategory__c>();
    
        //Loop over the wrapper
        for(ProductRuleCategoryWrapper cSplitWrap : listSplitCategoryWrap) {
            
            //Checking if Product category have actual date NOne
            if(cSplitWrap.revRecProductCategory.Category_End_Date__c != 'NONE') 
                cSplitWrap.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
            else 
                cSplitWrap.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
            
            //Checking if rule is not stamped 
            if(cSplitWrap.revRecProductCategory.RevRecProductRule__c == null)
                cSplitWrap.revRecProductCategory.RevRecProductRule__c = overrideRule.Id;
            
            //Populating ultimate parent on Splits
            if(cSplitWrap.revRecProductCategory.Ultimate_Parent__c == null) {
            
                //Checking if popup is open from parent screen 
                if(setParentScreenCategoryIds.contains(cSplitWrap.revRecProductCategory.RevRecProductRuleSplitCategory__c)) {
                    if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Ultimate_Parent__c',Constants.PERMISSION_UPSERT))
                        cSplitWrap.revRecProductCategory.Ultimate_Parent__c = listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Id;
                    ultimateParent = listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Id;
                }
                else {
                    cSplitWrap.revRecProductCategory.Ultimate_Parent__c = listSplitCategoryWrap[0].revRecProductCategory.Ultimate_Parent__c;
                    ultimateParent = listSplitCategoryWrap[0].revRecProductCategory.Ultimate_Parent__c;
                }
            }else
                ultimateParent = cSplitWrap.revRecProductCategory.Ultimate_Parent__c;
            
            //Setting values
            deferredAmount += cSplitWrap.revRecProductCategory.Deferred_Amount__c != null ? cSplitWrap.revRecProductCategory.Deferred_Amount__c : 0.00;
            recognizedAmount += cSplitWrap.revRecProductCategory.Recognized_Amount__c != null ? cSplitWrap.revRecProductCategory.Recognized_Amount__c : 0.00;
            actualDeferred += cSplitWrap.revRecProductCategory.Actual_Deferred__c != null ? cSplitWrap.revRecProductCategory.Actual_Deferred__c : 0.00;     
            totalSplitRecognized += cSplitWrap.revRecProductCategory.Recognized_Amount__c != null ? cSplitWrap.revRecProductCategory.Recognized_Amount__c : 0.00;
            totalSplitDeferred   += cSplitWrap.revRecProductCategory.Actual_Deferred__c != null ? cSplitWrap.revRecProductCategory.Actual_Deferred__c  : 0.00;
            
            //Add split into list to be upserted
            if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleCategory__c'))
                listSplitsToBeUpserted.add(cSplitWrap.revRecProductCategory);
            setCATIds.add(cSplitWrap.revRecProductCategory.Id)  ;
        }
        
        //Set is-split tag to true
        if(listSplitCategoryWrap.Size() > 0) {          
                        
            if(!setCATIds.contains(listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Id)) {
                listSplitsToBeUpserted.add(new RevRecProductRuleCategory__c(Id =listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Id ,
                                                                        Is_Split__c = true,
                                                                        Actual_Deferred__c = originalLineItemAmount - totalSplitRecognized, Recognized_Amount__c = totalSplitRecognized));
            
                setCATIds.add(listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].revRecProductCategory.Id);
            }
            
            //Checking for conditions
            if(mapParentIdWithListOfSplits.size() > 0 && mapParentIdWithListOfSplits.containsKey(categoryParentId)) {
                
                //Checking for conditioons
                if(screenNum >= 2 && !setCATIds.contains(mapParentIdWithListOfSplits.get(categoryParentId)[Integer.valueof(categoryToBeSplit) - 1].Id)) {
                    listSplitsToBeUpserted.add(new RevRecProductRuleCategory__c(Id =mapParentIdWithListOfSplits.get(categoryParentId)[Integer.valueof(categoryToBeSplit) - 1].Id,
                                                                        Is_Split__c = true, Deferred_Amount__c = deferredAmount, 
                                                                        Actual_Deferred__c = actualDeferred, Recognized_Amount__c = recognizedAmount));         
                    
                    setCATIds.add(mapParentIdWithListOfSplits.get(categoryParentId)[Integer.valueof(categoryToBeSplit) - 1].Id);
                }
            }
        }
        
        //Checking for the list size 
        if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleCategory__c')) {
            if(listSplitsToBeUpserted.size() > 0) {
                
                //Loop over mapOldRuleCategoryIdWithNewCatg and insert all categories
                for(RevRecProductRuleCategory__c prdCat : listSplitsToBeUpserted) {
                    
                    //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                    //If true the do this 
                    if(isMultiCurrencyEnabled) {
                        
                        if(prdCat.Actual_Deferred__c != null) {
                            prdCat.Converted_Actual_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Actual_Deferred__c)).replace('<br/>', '');
                            prdCat.Cor_Act_Def__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), prdCat.Actual_Deferred__c));
                        } else {
                            prdCat.Converted_Actual_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                        }
                        if(prdCat.Deferred_Amount__c != null) {
                            prdCat.Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Deferred_Amount__c)).replace('<br/>', '');
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
                }
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRuleCategory__c')){
                    upsert listSplitsToBeUpserted;
                }
            }
        }
        
        //Query over Product Categories
        for(RevRecProductRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                    Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                    Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Sub_Category_support__c,
                                                                    Projected_Qty__c, Projected_Amount__c, Projected_Percent__c,
                                                                    RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,RevRecProductRuleSplitCategory__r.Ultimate_Parent__c,
                                                                    (Select Id, Ultimate_Parent__c,Is_Split__c , Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                    Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c, Projected_Qty__c, Projected_Amount__c, Projected_Percent__c,
                                                                    Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Sub_Category_support__c,
                                                                    RevRecProductRule__c, RevRecProductRuleSplitCategory__c, RevRecProductRuleSplitCategory__r.Ultimate_Parent__c, Sequence__c From RevRecProductRuleSplitCategorys__r 
                                                                    ORDER BY Sequence__c) FROM RevRecProductRuleCategory__c
                                                                    Where RevRecProductRule__c =: overrideRule.Id ORDER BY CreatedDate ASC]) {
            
            //Checking for size of child //Populate map with values
            if(revCategory.RevRecProductRuleSplitCategorys__r.Size() > 0) 
                mapParentIdWithListOfSplits.put(revCategory.Id, revCategory.RevRecProductRuleSplitCategorys__r);
        } 
        
        //Varibles
        Decimal totalSplittedRollUpRecognized = 0.00;
        Decimal totalSplittedRollUpDeferred = 0.00;
        listSplitsToBeUpserted = new List<RevRecProductRuleCategory__c>();
        Boolean isRollUp = false;
        Integer ultimateParentseq ;
        
        //Query over Product Categoriesn which are child and not splitted yet
        for(RevRecProductRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                    Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                    Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Ultimate_Parent__r.Recognized_Amount__c,
                                                                    Ultimate_Parent__r.Actual_Deferred__c , Ultimate_Parent__r.Sequence__c, Projected_Qty__c, Projected_Amount__c, Projected_Percent__c,
                                                                    RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,Sub_Category_support__c,
                                                                    RevRecProductRuleSplitCategory__r.Ultimate_Parent__c FROM RevRecProductRuleCategory__c
                                                                    Where RevRecProductRule__c =: overrideRule.Id AND Is_Split__c = false AND
                                                                    RevRecProductRuleSplitCategory__c != null AND Ultimate_Parent__c != NULL  AND
                                                                    Ultimate_Parent__c =: ultimateParent ORDER BY CreatedDate ASC]) {
            
            
            //Roll up amount
            totalSplittedRollUpRecognized += revCategory.Recognized_Amount__c;
            totalSplittedRollUpDeferred += revCategory.Actual_Deferred__c;
            isRollUp = true;
            ultimateParentseq = Integer.valueOf(revCategory.Ultimate_Parent__r.Sequence__c);
        } 
        
         //Checking if any child exist then roll up amount
         if(isRollUp) {
            listSplitsToBeUpserted.add(new RevRecProductRuleCategory__c(Id = ultimateParent , Recognized_Amount__c = totalSplittedRollUpRecognized,
                                                                        Actual_Deferred__c = totalSplittedRollUpDeferred, Is_Split__c = true));
            isRollUp = false;
            listCategoryWrap[ultimateParentseq - 1].revRecProductCategory.Recognized_Amount__c = totalSplittedRollUpRecognized;
            listCategoryWrap[ultimateParentseq - 1].revRecProductCategory.Actual_Deferred__c  = totalSplittedRollUpDeferred;
            
         }
         
        //Query over Product Categoriesn which are child and not splitted yet
        for(RevRecProductRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                    Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                    Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c,Ultimate_Parent__r.Recognized_Amount__c,
                                                                    Ultimate_Parent__r.Actual_Deferred__c, RevRecProductRule__c, RevRecProductRuleSplitCategory__c, Sequence__c,
                                                                    RevRecProductRuleSplitCategory__r.Ultimate_Parent__c,Sub_Category_support__c, Projected_Qty__c, Projected_Amount__c, Projected_Percent__c,
                                                                    (Select Id, Ultimate_Parent__c,Is_Split__c , Name, Line_Item__c, Actual_Deferred__c, Actual_End_Date__c, Actual_Start_Date__c,
                                                                    Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Sub_Category_support__c,
                                                                    Deferred_Amount__c, Percent__c, Qty__c, Recognition_Type__c, Recognized_Amount__c, Projected_Qty__c, Projected_Amount__c, Projected_Percent__c,
                                                                    RevRecProductRule__c, RevRecProductRuleSplitCategory__c, RevRecProductRuleSplitCategory__r.Ultimate_Parent__c, Sequence__c
                                                                    From RevRecProductRuleSplitCategorys__r ORDER BY Sequence__c)
                                                                    FROM RevRecProductRuleCategory__c
                                                                    Where RevRecProductRule__c =: overrideRule.Id  AND
                                                                    RevRecProductRuleSplitCategory__c != null AND Ultimate_Parent__c != NULL  AND
                                                                    Ultimate_Parent__c =: ultimateParent ORDER BY CreatedDate ASC]) {
            
            //Roll up amount
            if(revCategory.RevRecProductRuleSplitCategorys__r.size() > 0) {
                
                //initilize
                totalSplittedRollUpRecognized = 0.00;
                totalSplittedRollUpDeferred = 0.00;
        
                //Loop over childs
                for(RevRecProductRuleCategory__c splitChild : revCategory.RevRecProductRuleSplitCategorys__r) {
                    totalSplittedRollUpRecognized += splitChild.Recognized_Amount__c;
                    totalSplittedRollUpDeferred += splitChild.Actual_Deferred__c;
                }
                //Roll up amounts
                revCategory.Recognized_Amount__c = totalSplittedRollUpRecognized;
                revCategory.Actual_Deferred__c = totalSplittedRollUpDeferred;
                if(Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Is_Split__c',Constants.PERMISSION_UPSERT))
                    revCategory.Is_Split__c = true;
            }
            //Add category into list 
            if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleCategory__c'))
            	listSplitsToBeUpserted.add(revCategory);
        }
     
        //Checking for the list size
        if(Utility.checkObjectPermission(Constants.PERMISSION_ACCESS, 'RevRecProductRuleCategory__c')){
            if(listSplitsToBeUpserted.size() > 0) {
                
                //Loop over mapOldRuleCategoryIdWithNewCatg and insert all categories
                for(RevRecProductRuleCategory__c prdCat : listSplitsToBeUpserted) {
                    
                    //Code modified -  (07/10/2017) - Check if multi currency enabled in org or not
                    //If true the do this 
                    if(isMultiCurrencyEnabled) {
                        
                        if(prdCat.Actual_Deferred__c != null) {
                            prdCat.Converted_Actual_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Actual_Deferred__c)).replace('<br/>', '');
                            prdCat.Cor_Act_Def__c = (utl.corporateCurrencyCalculation(String.valueOf(theOppty.get('CurrencyIsoCode')), prdCat.Actual_Deferred__c));
                        } else {
                            prdCat.Converted_Actual_Deferred_Amount__c = theOppty.get('REVvue_CurrencyType__c') + ' 0.00 ( ' + theOppty.get('CurrencyIsoCode') + ' 0.00 )';
                            prdCat.Cor_Act_Def__c = 0.00;
                        }
                        if(prdCat.Deferred_Amount__c != null) {
                            prdCat.Converted_Deferred_Amount__c = (utl.AmtWithDefaultCurrency(String.valueOf(theOppty.get('CurrencyIsoCode')), String.valueOf(theOppty.get('REVvue_CurrencyType__c')), prdCat.Deferred_Amount__c)).replace('<br/>', '');
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
                }
                if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecProductRuleCategory__c')){
                    upsert  listSplitsToBeUpserted; 
                }
            }
        }
    }
    /**
    *  @description    :   This method is used to add  row of category on  Override rule's Split screen
    *
    *  @args           :   
    *
    *  @return         :    void
    **/
    public void addCategoryForSplit () {
        
        //Current sequence
        Integer currentSequence = 0;
        
        //Loop over Category wrapper
        for(ProductRuleCategoryWrapper cWrap : listSplitCategoryWrap) {
            
            //Checking for selected category
            if(cWrap.isSelected) {
                currentSequence = 0;
                currentSequence = Integer.valueOf(cWrap.revRecProductCategory.Sequence__c);
            }   
            
            //Set false to the selected values
            cWrap.isSelected = false;       
        }
        
        //If currenct sequence is 0 then set this to high sequence
        if(currentSequence == 0)
            currentSequence = listSplitCategoryWrap.size();
        
        //Create a new category instance 
        RevRecProductRuleCategory__c category1 = new RevRecProductRuleCategory__c(Sequence__c = currentSequence + 1, Name = '', Category_Start_Date__c = constants.MILESTONE_DATE_MANUAL ,
                                                                                  Category_End_Date__c = 'None', Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION,
                                                                                  RevRecProductRuleSplitCategory__c = listSplitCategoryWrap[0].revRecProductCategory.RevRecProductRuleSplitCategory__c);
        
        //Loop over Category wrapper
        for(ProductRuleCategoryWrapper cWrap : listSplitCategoryWrap) {
            
            if(cWrap.revRecProductCategory.Sequence__c > currentSequence) {
                
                //Assign sequence
                cWrap.revRecProductCategory.Sequence__c += 1; 
                
                //Initilize list of select option for every wrap instance
                lineItemForBlended = new List<SelectOption>();
                
                //Loop to create the line item options 
                for(Integer i=0 ; i< cWrap.revRecProductCategory.Sequence__c ; i++)
                    lineItemForBlended.add(new SelectOption(String.valueOf(i) , String.valueOf(i)));
                
                //Assign line item for blended 
                cWrap.lineItemForBlended = lineItemForBlended;
            }
        } 
        //Inilitilize list of select option
        lineItemForBlended = new List<SelectOption>();
        
        //Loop over category sequence
        for(Integer j=0 ; j<= currentSequence ; j++)
            lineItemForBlended.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
        
        listSplitCategoryWrap.add(new ProductRuleCategoryWrapper (category1, currentSequence + 1 , lineItemForBlended, false));
        
        
        //Map to hold wrapper record with sequence
        Map<Integer, ProductRuleCategoryWrapper> mapSeqWithCatWrap = new   Map<Integer, ProductRuleCategoryWrapper>();
        
        //Loop over List category wrapper
        for(ProductRuleCategoryWrapper cWrap : listSplitCategoryWrap) {
            mapSeqWithCatWrap.put(Integer.valueOf(cWrap.revRecProductCategory.Sequence__c)  , cWrap);
        }
        
        //List of Sequence
        List<Integer> listSequences = new List<Integer>();
        listSequences.addAll(mapSeqWithCatWrap.keySet());
        listSequences.sort();
        
        //Clear wrapper class   
        listSplitCategoryWrap.clear();
        
        //Loop over sequences
        for(Integer seq  : listSequences) {   
            
            //Re-Populate the value         
            listSplitCategoryWrap.add(mapSeqWithCatWrap.get(seq));
        }
    }
    /**
     *  @description    :   This method is used to remove row from override rule's split screen
     *
     *  @args           :   
     *
     *  @return     :   void
    **/
    public void removeCategoryForSplit () {
        
        //Set to hold sequence
        Set<Integer> setSequences = new Set<Integer>();
        Set<String> setString = new Set<String>();
        
        //Map to hold Wrapper with sequence
        Map<Integer, ProductRuleCategoryWrapper> mapSeqWithWrap = new Map<Integer, ProductRuleCategoryWrapper>();
        
        for(ProductRuleCategoryWrapper catWrap : listSplitCategoryWrap) 
            mapSeqWithWrap.put(Integer.valueOf(catWrap.revRecProductCategory.sequence__c), catWrap);
        
        //Loop over wrapper class and checking for the selected record 
        for(ProductRuleCategoryWrapper productCatWrapper : listSplitCategoryWrap) {
            
            //Checking for Selected value
            if(productCatWrapper.isSelected) {
                setSequences.add(Integer.valueOf(productCatWrapper.revRecProductCategory.Sequence__c));
                setString.add(productCatWrapper.revRecProductCategory.Name);
            }
            
            //Set selected value to false
            productCatWrapper.isSelected = false;
        } 
        
        //For no any selected value 
        //Checking for the set size 
        if(setSequences.size() == 0  && setString.size() == 0) {
            
            setSequences.add(Integer.valueOf(listSplitCategoryWrap[listSplitCategoryWrap.size() - 1].revRecProductCategory.Sequence__c));
            setString.add(listSplitCategoryWrap[listSplitCategoryWrap.size() - 1].revRecProductCategory.Name);
        }     
        
        //Loop over set and remove selected from the list
        if(setSequences.size() > 0) {
            
            for(Integer seq : setSequences)
                mapSeqWithWrap.remove(Integer.valueOf(seq));
        }
        
        //Initlize category wrap and assign temp list to wrapper
        listSplitCategoryWrap = new List<ProductRuleCategoryWrapper>();
        listSplitCategoryWrap = mapSeqWithWrap.values();
        Integer j = 0;
        
        //Loop over Category wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listSplitCategoryWrap) {
            productCatWrapper.revRecProductCategory.Sequence__c = j+1; 
            productCatWrapper.rowCount = j;
            j++;
        }
        
        //If any value selected 
        if(setSequences.size() > 0) {
           
            //Delete Rule category
            for(RevRecProductRuleCategory__c ruleCatsToDelete : [Select Id From RevRecProductRuleCategory__c WHERE  Name IN : setString AND RevRecProductRule__c =: overrideRule.Id])
                setSplitCategoriesToBeDeleted.add(ruleCatsToDelete.Id);
        }
    }
    /**
     *  @description    :   This method is call on change of start date drop down and again calculate the recognized and deferred amount for Split.
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public  void onChangeStartOptionsForSplitBlended () {
        
        //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualDeferred;
        Decimal actualCatDifference = 0.00;
        Decimal amountToSplit = originalLineItemAmount;
        Decimal qtyToSplit = originalLineItemQty;
        Decimal outstandingBalance = originalLineItemAmount;
        String msg = '';
        
        //Getting parameter
        startRowNumber = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('startRowNum'));
        
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listSplitCategoryWrap) {
       
            //Checking for rowCount
            if(startRowNumber == productCatWrapper.rowCount) {
            
                //Seetting Recognition Type
                if(productCatWrapper.revRecProductCategory.Category_End_Date__c != 'NONE' && Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Recognition_Type__c',Constants.PERMISSION_UPSERT))
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE;
                else
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
                    
                //Calculate Start and End Date on change of start and End Date drop down change
                productCatWrapper.revRecProductCategory = calculateStartDateFrBlendedRev(productCatWrapper.revRecProductCategory, oli, theOppty, product2, contract);
                 
                //Reset values
                recognizedAmount = 0.00;
                deferredAmount = 0.00;
                actualDeferred = 0.00;
                
                //Setting app setting
                RevRecUtil.appSetting = theSetting;
                
                //Calling method to calculate recognized and deferred amount
                wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlendedSplit(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listSplitCategoryWrap, actualDeferred, amountToSplit, qtyToSplit, overrideRule);
                
                recognizedAmount = wrapCalculation.recognizedAmount;
                deferredAmount = wrapCalculation.deferredAmount;
                actualDeferred = wrapCalculation.actualDeferred;
                outstandingBalance = wrapCalculation.outStandingBalance;
                actualCatDifference = wrapCalculation.actualCatDifference;
                msg = wrapCalculation.msg;   
                
                //Set values in Product Category
                productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
                productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
                productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
                outstandingBalance = outstandingBalance - actualCatDifference; 
            }                
        }
        calculateSplit();
    }
    /**
     *  @description    :   This method is call on change of End date drop down and again calculate the recognized and deferred amount.
     *
     *  @args           :   
     *
     *  @return         :   void
    **/
    public  void onChangeEndOptionsForBlendedSplit () {
        
        //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualCatDifference = 0.00;
        Decimal actualDeferred;
        Decimal amountToSplit = originalLineItemAmount;
        Decimal qtyToSplit = originalLineItemQty;
        Decimal outstandingBalance = oli.TotalPrice;
        String msg = '';
        
        //Getting end row number from parameters
        endRowNumber = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('endRowNumber'));
        
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listSplitCategoryWrap) {
            
            //Checking for rowCount
            if(endRowNumber == productCatWrapper.rowCount) {
                
                //Setting Recognition Type
                if(productCatWrapper.revRecProductCategory.Category_End_Date__c != 'NONE' && Utility.checkFieldPermission(mapfieldProdRuleCatResult,'Recognition_Type__c',Constants.PERMISSION_UPSERT))
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_AMORTIZE;
                else
                    productCatWrapper.revRecProductCategory.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
                
                //Calculate Start and End Date on change of start and End Date drop down change
                productCatWrapper.revRecProductCategory = calculateEndDateFrBlendedRev(productCatWrapper.revRecProductCategory, oli, theOppty, product2, contract);
                
                //Reset values
                recognizedAmount = 0.00;
                deferredAmount = 0.00;
                actualDeferred = 0.00;
                
                 //Setting app setting
                RevRecUtil.appSetting = theSetting;
                
                //Calling method to calculate recognized and deferred amount
                wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlendedSplit(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listSplitCategoryWrap, actualDeferred, amountToSplit,qtyToSplit, overrideRule);
                
                recognizedAmount = wrapCalculation.recognizedAmount;
                deferredAmount = wrapCalculation.deferredAmount;
                actualDeferred = wrapCalculation.actualDeferred;
                outstandingBalance = wrapCalculation.outStandingBalance;
                actualCatDifference = wrapCalculation.actualCatDifference;
                msg = wrapCalculation.msg; 
                    
                //Set values in Product Category
                productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
                productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
                productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
                outstandingBalance = outstandingBalance - actualCatDifference; 
            }
        }
        calculateSplit();
    }
    /**
     *  @description    :   This method is used to format the dates according to the the selected date field.
     *
     *  @args           :   RevRecProductRuleCategory__c cat
     *
     *  @return         :   Void
    **/
    public void formatDateForOverrideCategory (RevRecProductRuleCategory__c cat) {
        
        //Variable
        Date actualStartDate;
        Date actualEndDate;
        
        //Get the start date and end date    
        String RevRecStartDate = cat.Category_Start_Date__c;
        String RevRecEndDate = cat.Category_End_Date__c;
        
        //Checking if start date not null and Conatins Opportunity , product or Blank
        if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_OPPORTUNITY)){
            if(RevRecStartDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            
                string fieldName = RevRecStartDate.subString(20, RevRecStartDate.length()); 
                actualStartDate = (Date)oli.get(fieldName);
            }
            else {
                
                string fieldName = RevRecStartDate.subString(12, RevRecStartDate.length()); 
                actualStartDate = (Date)theoppty.get(fieldName);
            }
        } else if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            string fieldName = RevRecStartDate.subString(8, RevRecStartDate.length());
            actualStartDate = (Date)product2.get(fieldName);
        } else if (RevRecStartDate != null && RevRecStartDate.contains(constants.SOBJECT_CONTRACT_COLON)) {
            string fieldName = RevRecStartDate.subString(9, RevRecStartDate.length());
            actualStartDate = (Date)contract.get(fieldName);
        } else if(RevRecStartDate != null && RevRecStartDate.equalsIgnoreCase(constants.MILESTONE_DATE_MANUAL)) 
            actualStartDate = cat.Actual_Start_Date__c != null ?  cat.Actual_Start_Date__c : null;
        else if (RevRecStartDate != null && RevRecStartDate.equalsIgnoreCase('NONE')) 
            actualStartDate =  null;
        
        //Checking if end date not null and Conatins Opportunity , product or Blank
        if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_OPPORTUNITY)){
            if(RevRecEndDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            
                string fieldName = RevRecEndDate.subString(20, RevRecEndDate.length()); 
                actualEndDate = (Date)oli.get(fieldName);
            }
            else {
                
                string fieldName = RevRecEndDate.subString(12, RevRecEndDate.length()); 
                actualEndDate = (Date)theoppty.get(fieldName);
            }
        } else if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_LINE_ITEM_COLON)) {
            string fieldName = RevRecEndDate.subString(8, RevRecEndDate.length());
            actualEndDate = (Date)product2.get(fieldName);
        }else if (RevRecEndDate != null && RevRecEndDate.contains(constants.SOBJECT_CONTRACT_COLON)) {
            string fieldName = RevRecEndDate.subString(9, RevRecEndDate.length());
            actualEndDate = (Date)contract.get(fieldName);
        } else if (RevRecEndDate != null && RevRecEndDate.equalsIgnoreCase('NONE')) 
            actualEndDate =  null;
        else if (RevRecEndDate != null && RevRecEndDate.equalsIgnoreCase(constants.MILESTONE_DATE_MANUAL))  
            actualEndDate =   cat.Actual_End_Date__c != null ?  cat.Actual_End_Date__c : null;
      
        //Set Date from variables
        cat.Actual_Start_Date__c =  actualStartDate;
        cat.Actual_End_Date__c = actualEndDate;
       
    }
    /**
     *  @description    :   This method is used to calculate the blended Categories.
     *
     *  @args           :   -
     *
     *  @return         :   -
    **/
    public void calculateBlendedCategories() {
        System.debug('calculateBlendedCategories...@@@');
        
         //Variables to hold recognized and deferred amount
        Decimal recognizedAmount ;
        Decimal deferredAmount;
        Decimal actualDeferred;
        Decimal actualCatDifference;
        Decimal outstandingBalance = oli.TotalPrice;
        String msg = '';
        totalRecognized = 0.00;
        totalDeferred = 0.00;
        totalRemainingBlended = 0.00;
		Decimal sumOfCatRecogRev = 0.00;      
        Decimal sumOfCatDeferRev = 0.00;      
                
        //Loop through wrapper
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
                                        
            //Checking if Product category have actual date NOne and setting Recognition Type
            if(productCatWrapper.revRecProductCategory.Category_End_Date__c != 'NONE') 
                productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
            else 
                productCatWrapper.revRecProductCategory.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
            
            //Calculate Start and End Date on change of start and End Date drop down change
            productCatWrapper.revRecProductCategory = calculateEndDateFrBlendedRev(productCatWrapper.revRecProductCategory, oli, theOppty, product2, contract);
            
            //Reset values
            recognizedAmount = 0.00;
            deferredAmount = 0.00;
            actualDeferred = 0.00;
            
             //Setting app setting
             RevRecUtil.appSetting = theSetting;
             
            //Calling method to calculate recognized and deferred amount
            wrapCalculation = RevRecUtil.calculateRecAndDeferredRevForBlended(productCatWrapper.revRecProductCategory, outstandingBalance, recognizedAmount, deferredAmount, oli, msg, null, listCategoryWrap, actualDeferred, overrideRule);
            
            recognizedAmount = wrapCalculation.recognizedAmount;
            deferredAmount = wrapCalculation.deferredAmount;
            actualDeferred = wrapCalculation.actualDeferred;
            outstandingBalance = wrapCalculation.outStandingBalance;
            actualCatDifference = wrapCalculation.actualCatDifference;
            msg = wrapCalculation.msg;   
            
            //Set values in Product Category
            productCatWrapper.revRecProductCategory.Recognized_Amount__c = recognizedAmount;
            productCatWrapper.revRecProductCategory.Deferred_Amount__c = deferredAmount;
            productCatWrapper.revRecProductCategory.Actual_Deferred__c = actualDeferred;
            outstandingBalance = outstandingBalance - actualCatDifference;                 
        }
        
        //Loop over categories
        for(ProductRuleCategoryWrapper productCatWrapper : listCategoryWrap) {
            
            totalRecognized += productCatWrapper.revRecProductCategory.Recognized_Amount__c;
            totalDeferred += productCatWrapper.revRecProductCategory.Actual_Deferred__c;
            sumOfCatRecogRev += productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
            sumOfCatDeferRev += productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
            
            if(sumOfCatRecogRev-totalRecognized >= 0.01) {
            	Decimal recogAmount = productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
            	recogAmount -= (sumOfCatRecogRev-totalRecognized);
            	productCatWrapper.revRecProductCategory.Recognized_Amount__c = recogAmount;
            	sumOfCatRecogRev -= (sumOfCatRecogRev-totalRecognized);
            } else if(totalRecognized-sumOfCatRecogRev >= 0.01) {
            	Decimal recogAmount = productCatWrapper.revRecProductCategory.Recognized_Amount__c.setScale(2);
            	recogAmount += (totalRecognized-sumOfCatRecogRev);
            	productCatWrapper.revRecProductCategory.Recognized_Amount__c = recogAmount;
            	sumOfCatRecogRev += (totalRecognized-sumOfCatRecogRev);
            }
            if(sumOfCatDeferRev-totalDeferred >= 0.01) {
            	Decimal deferAmount = productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
            	deferAmount -= (sumOfCatDeferRev-totalDeferred);
            	productCatWrapper.revRecProductCategory.Actual_Deferred__c = deferAmount;
            	sumOfCatDeferRev -= (sumOfCatDeferRev-totalDeferred);
            } else if(totalDeferred-sumOfCatDeferRev >= 0.01) {
            	Decimal deferAmount = productCatWrapper.revRecProductCategory.Actual_Deferred__c.setScale(2);
            	deferAmount += (totalDeferred-sumOfCatDeferRev);
            	productCatWrapper.revRecProductCategory.Actual_Deferred__c = deferAmount;
            	sumOfCatDeferRev += (totalDeferred-sumOfCatDeferRev);
            }
            
            if((totalRecognized+totalDeferred) == lineItem.TotalPrice) {
            	if((sumOfCatRecogRev+sumOfCatDeferRev) < (totalRecognized+totalDeferred)) {
            		if(totalRecognized != 0.00) {
            			if(productCatWrapper.revRecProductCategory.Recognized_Amount__c != 0.00) {
            				productCatWrapper.revRecProductCategory.Recognized_Amount__c += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
            				Decimal totalRec = totalRecognized.setScale(2);
            				totalRec += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
            				totalRecognized = totalRec;
            				sumOfCatRecogRev = totalRec;
            			}
            		} else if(totalDeferred != 0.00) {
            			if(productCatWrapper.revRecProductCategory.Actual_Deferred__c != 0.00) {
            				productCatWrapper.revRecProductCategory.Actual_Deferred__c += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
            				Decimal totalDef = totalDeferred.setScale(2);
            				totalDef += ((totalRecognized+totalDeferred) - (sumOfCatRecogRev+sumOfCatDeferRev));
            				totalDeferred = totalDef;
            				sumOfCatDeferRev = totalDef;
            			}
            		}
            	}
            }
        }
        
        //Code added on 25/07/2016 - Terry Issue # 2: Remaining Values
        //Remianing amount, percentage, quantity
        revRecLineItem.Remaining_Amount__c = (lineItem.TotalPrice - (totalRecognized + totalDeferred)).setScale(2);
        
        if(lineItem.TotalPrice > 0) {
            revRecLineItem.Remaining_Percentage__c = (((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice))*100).setScale(2);
            revRecLineItem.Remaining_Qty__c = ((revRecLineItem.Remaining_Amount__c) / (lineItem.TotalPrice/lineItem.Quantity)).setScale(2);
        }else {
            revRecLineItem.Remaining_Percentage__c = 0.00;
             revRecLineItem.Remaining_Qty__c = 0.00;
        }
     }
    
    /**
     *  @description    :   This method is called on change of divide by option.If its prorate then rerender By percentage 
     *
     *  @args           :
     *
     *  @return         :   
    **/
    public void onChangeDivideByOption () {
        
        //Checking for values and set default value
        if(overrideRule.Divide_By__c != 'prorate') 
            overrideRule.Period_or_Exact_Days__c = 'period';
        else 
            overrideRule.Period_or_Exact_Days__c = 'exact';
    }
    
    /**
     *  @description    :   This method is called on change of period or exact days options
     *
     *  @args           :
     *
     *  @return         :   
    **/
    public void onChangeExactDaysOptions () {}
    
    /**
     *  @description    :   This method is used to adjust the remaining revenue for amortized milestone.
     *                      FEATURE # 3: Add Adjust Future Revenue button to Amortized Milestone override screen.
     *
     *  @args           :
     *
     *  @return         :   void
     **/
    public void adjustFutureRevenue() {
        
        //Variable inialization
        //Hold the recognized amount till today
        Double recogniedAmount = 0;
        
        //Hold the recognized Quantity till today
        Double recogniedQty = 0;
        
        //Hold value to assign in amount/quantity
        Decimal assignAmountOrQty = 0;
        
        //Hold recognized mounth counter
        Integer i=0;
        
        //Flag to update Quantity
        Boolean isQty = false;
        Boolean isAmount = false;
        Decimal residualPercent = 0.00;
        Decimal recognizableValue = 0.00;
        Decimal initialValue = 0.00;
        Date firstMilestoneDate;
        Boolean isPercent = false;
        Double recogniedPercent = 0;
        
        if(overrideRule.Residual_Amount__c != null) {
            if(overrideRule.Residual_Amount_Type__c == 'Percent')
                residualPercent = overrideRule.Residual_Amount__c;
            else if(overrideRule.Residual_Amount_Type__c == 'Amount')
                residualPercent = (overrideRule.Residual_Amount__c*100)/lineItem.TotalPrice;
        }
        
        //Check if, map have value
        if(revRecProductRuleMilestones.size() > 0 && revRecLineItem != null) {
            
            Date initialStartDate = revRecProductRuleMilestones[0].Milestone_Date__c;
            
            Boolean startInCurrentMonth = false;
            
            if(initialStartDate != null ) {
                if (theSetting.Time_of_Month_Selection_Types__c == '1') { //last day of the month
                        // do nothing
                } else if (theSetting.Time_of_Month_Selection_Types__c == '2') { // Date of the month
                    Integer settingDateInTheMonth = Integer.valueOf(theSetting.Certain_date_of_month__c);
                    if (initialStartDate.day() > settingDateInTheMonth) {
                        startInCurrentMonth = false;
                    }
                } else if (theSetting.Time_of_Month_Selection_Types__c == '3') { //certain weekday of certain week
                    Date certainWeekCertainWeekdayForStartDate =RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(initialStartDate, theSetting.Certain_weekday__c, theSetting.Certain_weekday_day__c);
                    if (initialStartDate > certainWeekCertainWeekdayForStartDate) {
                        startInCurrentMonth = false;
                    }
                }
            }
            
            Decimal wholeAMT = 0.00;
            firstMilestoneDate = revRecProductRuleMilestones[0].Milestone_Date__c;
            //Lopp over milestones
            for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                
                Date transDate = getTransDate(item.Milestone_Date__c, startInCurrentMonth);
                
                //Checking for milestone date with current date
                if(item.Milestone_Date__c <= Date.Today()) {
                    
                    if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty'))
                        recogniedQty += item.Actual_Qty__c != null ? (item.Actual_Qty__c) : 0.00; //Total recognized amount till current date
                    
                    else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount'))
                        recogniedAmount += item.Actual_Amount__c != null ? (item.Actual_Amount__c) : 0.00; //Total recognized qty till current date
                    
                    else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Percent'))  
                    	recogniedPercent += item.Actual_Percent__c != null ? (item.Actual_Percent__c) : 0.00; //Total recognized percent till current date
                    //Counter increment
                    i++;
                }  
                
                wholeAMT +=  (item.Actual_Amount__c);
            }
            
            //Check if, future month remaing
            if(revRecProductRuleMilestones.size()-i > 0) {
                
                //Check if, recognized amount is less or equal with line item total amount
                if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount') && recogniedAmount <= lineItem.TotalPrice)
                    isAmount = true;	//Setting flag
                else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty') && recogniedQty <= lineItem.Quantity)
                    isQty = true;	//Setting flag
                else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('percent') && recogniedPercent <= 100)
                    isPercent = true;	//Setting flag
            }
                        
            //Check if, amount/quantity to update
            if(isQty || isAmount || isPercent) {
            
                Date startDate ;
                Date endDate;
                
                if(startDate == null) 
                    startDate = revRecProductRuleMilestones[ i].Milestone_Date__c.toStartOfMonth();
                
                //Check if first row is in future date item
                if(firstMilestoneDate == revRecProductRuleMilestones[ i].Milestone_Date__c) {
                	
                	//Check for Initial Amount
                    if(overrideRule.initial_Amount__c != null && overrideRule.initial_Amount__c != 0.00) {
                    	
                    	//Check for Initial Amount type whether amount or percent, and get initial value
                        if(overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
                            if(overrideRule.Initial_Amount_Type__c == 'Amount')
                            	initialValue = overrideRule.initial_Amount__c;
                        	else if(overrideRule.Initial_Amount_Type__c == 'Percent')
                        		initialValue = (overrideRule.initial_Amount__c*lineItem.TotalPrice)/100;
                        }
                        else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                            if(overrideRule.Initial_Amount_Type__c == 'Amount')
                            	initialValue = (overrideRule.initial_Amount__c*lineItem.Quantity)/lineItem.TotalPrice;
                        	else if(overrideRule.Initial_Amount_Type__c == 'Percent')
                        		initialValue = (overrideRule.initial_Amount__c*lineItem.Quantity)/100;
                        }
                        else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('percent')) {
                        	if(overrideRule.Initial_Amount_Type__c == 'Amount')
                            	initialValue = (overrideRule.initial_Amount__c*100)/lineItem.TotalPrice;
                        	else if(overrideRule.Initial_Amount_Type__c == 'Percent')
                        		initialValue = overrideRule.initial_Amount__c;
                        }
                    }
                }
                
                if(endDate == null) 
                    endDate = overrideRule.End_Date__c;
                    
                Integer totalMonths = startDate.MonthsBetween(endDate);
                List<Decimal> recogngibleAmtList = new List<Decimal>();  
                totalMonths = utilHelper.getTotalMonths(startDate  , endDate , totalMonths , overrideRule);
               	
               	if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount'))
               		recognizableValue = (lineItem.TotalPrice - recogniedAmount -(residualPercent*lineItem.TotalPrice)/100) - initialValue;
           		else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) 
           			recognizableValue = (lineItem.Quantity - recogniedQty -(residualPercent*lineItem.Quantity)/100) - initialValue;
       			else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('percent')) 
           			recognizableValue = (100 - recogniedPercent - residualPercent - initialValue);
           		
                recogngibleAmtList = utilHelper.getRecognigibleFORAM(startDate, endDate, overrideRule, recognizableValue, totalMonths, recogngibleAmtList, initialValue);
                Integer j = 0;
                
                //Loop over milestones 
                for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
                                      
                  Date transDate = getTransDate(item.Milestone_Date__c, startInCurrentMonth);
                	
                    //Checking for milestone date with current date
                    //if(transDate >  Date.Today()) {
                    if(item.Milestone_Date__c > Date.Today()) {
                    	if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount'))
                        	item.Actual_Amount__c = recogngibleAmtList[j];
                    	else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty'))
                        	item.Actual_Qty__c = recogngibleAmtList[j];
                    	else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('percent'))
                        	item.Actual_Percent__c = recogngibleAmtList[j];
                        j++;
                    }                    
                }
                
            } else {
                
                isShowAdjuctAndPricingButton = true;
                
                //Adding error message
                String msg = label.REVENUE_CAN_NOT_EXCEED_OPPTY_PRODUCT_AMOUNT; 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg )); 
            }
        }        
    }
    
    /**
     *  @description    :   This method is used to adjust the amount of opportunitylineitem for amortized milestone.
     *                      Enhancement #3: Ability to adjust line item price/opportunity amount when changes to Actual Forecast is greater than the line item amount.
     *
     *  @args           :
     *
     *  @return         :   void
     **/
    public void AdjustProductPricingOpportunityAmount() {
        
        //Variable
        //Variable to hold amount to update on line item
        Double lineItemPriceToUpdate = 0.00;
        Double lineItemSalesPriceToUpdate = 0.00;
        Double lineItemQtyToUpdate = 0.00;
        Decimal residualPercent = 0.00;
        Decimal percentDifference = 0.00;
        Integer totalMonths = 0;
        Decimal initialValue = 0.00;
        if(overrideRule.Residual_Amount__c != null) {
            if(overrideRule.Residual_Amount_Type__c == 'Percent')
                residualPercent = overrideRule.Residual_Amount__c;
            else if(overrideRule.Residual_Amount_Type__c == 'Amount')
                residualPercent = (overrideRule.Residual_Amount__c*100)/lineItem.TotalPrice;
        }
        
        //Check if, map have value
        if(revRecProductRuleMilestones.size() > 0 && revRecLineItem != null) {
            
            //Lopp over milestones
            for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones){
                
                //Check for future date
                if(item.Milestone_Date__c > Date.today())
                	totalMonths++;
                	
                //for AM rule
                if(overrideRule.Recognition_Type__c ==  constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                    
                    if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount'))
                    	lineItemPriceToUpdate += item.Actual_Amount__c != null ? item.Actual_Amount__c : 0.00;
                    else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('percent'))
                        lineItemPriceToUpdate += item.Actual_Percent__c != null ? (item.Actual_Percent__c).setScale(2) : 0.00;
                    else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty'))
                        lineItemPriceToUpdate += item.Actual_Qty__c != null ? item.Actual_Qty__c : 0.00;
                } 
                
                //For milestone type
                if(overrideRule.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                     lineItemPriceToUpdate += item.Amount__c != null ? item.Amount__c : 0.00;
                }
            }
        }
         
        //Check for update
        if(lineItemPriceToUpdate > 0)  {

            if(overrideRule.Milestone_Type__c.equalsIgnoreCase('Amount')) {
                lineItem.TotalPrice = ((lineItemPriceToUpdate/(100-residualPercent))*100).setScale(2);
                
                if(overrideRule.Residual_Amount_Type__c != null && overrideRule.Residual_Amount_Type__c.equalsIgnoreCase('Amount')) {
                    if(Utility.checkFieldPermission(mapfieldProdRuleResult,'Residual_Amount__c',Constants.PERMISSION_UPSERT))
                        overrideRule.Residual_Amount__c = (residualPercent * lineItem.TotalPrice) / 100;
                }
            }
            else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
                
            	if(residualPercent != null && residualPercent != 0)
		            lineItem.Quantity = ((lineItemPriceToUpdate/(100-residualPercent))*100).setScale(2);
                else
                    lineItem.Quantity = Decimal.valueOf(lineItemPriceToUpdate).setScale(2);
            }
            else if(overrideRule.Milestone_Type__c.equalsIgnoreCase('percent')) {
            	
            	Decimal overallDifference = (lineItemPriceToUpdate - (100 - residualPercent));
            	percentDifference = overallDifference/totalMonths;
            	
            	//Loop over milestones
            	for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
            		
            		//Check for future date
            		if(item.Milestone_Date__c > Date.today()) {
            			item.Actual_Percent__c = (item.Actual_Percent__c.setScale(2) - percentDifference.setScale(2));
            			overallDifference -= percentDifference.setScale(2);
	            		item.Actual_Amount__c = (item.Actual_Percent__c*lineItem.TotalPrice)/100;
	            		item.Actual_Qty__c = (item.Actual_Amount__c/lineItem.TotalPrice)*lineItem.Quantity;
            		}
            	}
            	//If difference is still not zero as setScale(2) make some changes, then add the remaining percent in last percent 
            	if(overallDifference != 0) {
                    if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Actual_Percent__c',Constants.PERMISSION_UPSERT))
                        revRecProductRuleMilestones[revRecProductRuleMilestones.size()-1].Actual_Percent__c += Math.abs(overallDifference);
                    if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Actual_Amount__c',Constants.PERMISSION_UPSERT))
                        revRecProductRuleMilestones[revRecProductRuleMilestones.size()-1].Actual_Amount__c = (revRecProductRuleMilestones[revRecProductRuleMilestones.size()-1].Actual_Percent__c*lineItem.TotalPrice)/100;
                    if(Utility.checkFieldPermission(mapfieldProdRuleMilesResult,'Actual_Qty__c',Constants.PERMISSION_UPSERT))
                        revRecProductRuleMilestones[revRecProductRuleMilestones.size()-1].Actual_Qty__c = (revRecProductRuleMilestones[revRecProductRuleMilestones.size()-1].Actual_Amount__c/lineItem.TotalPrice)*lineItem.Quantity;
                }
            }

            //For AM Rule, reset residual amount if any
            if(overrideRule.Recognition_Type__c ==  constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
                residualAmount = (lineItem.TotalPrice - lineItemPriceToUpdate).setScale(2);
            }
        }
        
        IsLIAmountChanged = true;
    }
    
    /** This method is used to get the transaction date in the case of adjust future revenue**/
    public  Date getTransDate(Date theDate, boolean inCurrentMonth) {
        
        Date returnDate = theDate;
        
        //default is first day of the month
        integer transactionDay = theDate.toStartOfMonth().day();
        
        if (theSetting.Time_of_Month_Selection_Types_tr__c == '1') { //last day of the month
            transactionDay = theDate.toStartOfMonth().addMonths(1).addDays(-1).day();
        } else if (theSetting.Time_of_Month_Selection_Types_tr__c == '2') { // Date of the month
            transactionDay = Integer.valueOf(theSetting.Certain_date_of_month_tr__c);
        } else if (theSetting.Time_of_Month_Selection_Types_tr__c == '3') { //certain weekday of certain week
            Date calculated = RevRecHelper.GetDateByCertainWeekCertainDayOfWeek(theDate, theSetting.Certain_weekday_tr__c, theSetting.Certain_weekday_day_tr__c);
            transactionDay = calculated.day();
        }
                
        returnDate = date.newinstance(returnDate.year(), returnDate.month(), transactionDay);
                
        return returnDate;
    } 
    
    /** Method is used to format date in tthe case of lightning**/
    private static String formatDate(Date d) {
        
        if(d != null) {
            
            String day = String.valueOf(d.day());
            String mon = String.valueOf(d.month());
             
            if(d.day() < 10)
                day = '0'+day;
            if(d.month() < 10)
                mon = '0'+ mon;
        
            return mon + '/' +day + '/' + d.year(); 
        }       
        return null; 
    }
    
    /**  This method is used to check if revenue scheduless are available for the org**/
    public static boolean schedulesEnabledForOrg() {
        Schema.DescribeSObjectResult describeSObjectResult = Product2.SObjectType.getDescribe();
        return describeSObjectResult.fields.getMap().containsKey('CanUseRevenueSchedule');
    }
    
    /**
     *  @description    :   This method is used to Initializing Sales Forecast and Actual Forescast 
     *                  :   with 0 Values to Amortized Milestone override screen
     *
     *  @args           :
     *
     *  @return         :   void
     **/
    public void initializSalesAndActualForecast() { 
        
        IsInitializZero = true;
        
        for(RevRecProductRuleMilestone__c item : revRecProductRuleMilestones) {
            
            item.Actual_Amount__c = 0.0;
            item.Actual_Qty__c = 0.0;
            item.Projected_Amount__c = 0.0;
            item.Projected_Qty__c = 0.0;
        }         
    }
    
    /**
     *  @description    :   This method is used to make page in edit mode for user interaction.
     *
     *  @args           :
     *
     *  @return         :   void
     **/
    public void onEditableMode() {
    	
    	editable = false;
    	if(showValidateAMAgainstLI == true) {
    		editable = true;
    	} else {
			editable = false;
			errVisibility = true; 
		}		
    }
    /**
     *  @description    :   This method is used to get RevRecRule.
     *
     *  @args           :
     *
     *  @return         :   void
     **/
     public RevRecRules__c getRule() { return rule; }
}