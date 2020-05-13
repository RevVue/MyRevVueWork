public with sharing class RevRecRuleController {
     
    //Variables
	public RevRecAppSetting__c theSetting;
    RevRecRules__c rule;
    Map<String, String> allDates; 
    String ruleIdToEdit;
    
    //String to hold index values
	public String indexString {get; set;} 
   
    //Code added = 04/03/2015  - As per Urgent issue bug fix
    public string milestoneDateSource; 
    
    //Code added - 04/04/2016 - As per Split template creation on default rule level //
    //Variables for split functionality
    public String lineItemRow {get;set;}
    public List<CategoryWrapper> listSplitCategoryWrap {get;set;}
    
    //Map is used to hold the field permission
    Static Map<String, Schema.DescribeFieldResult> mapfieldCatResult = Utility.getFieldPermissions('RevRecRuleCategory__c');
    Static Map<String, Schema.DescribeFieldResult> mapfieldRuleResult = Utility.getFieldPermissions('RevRecRules__c');
    Static Map<String, Schema.DescribeFieldResult> mapfieldAppSetResult = Utility.getFieldPermissions('RevRecAppSetting__c');
    
    public List<RevRecRuleWrapper> getRevRecRules () {
         
        //RevRec Rule
        List<RevRecRules__c> RevRecRules = null;
        
        if (showInActive)     
            RevRecRules = [SELECT Id, name, Active__c, Default_Rule__c, Description__c, Divide_By__c, initial_amount__c,Milestone_Type__c, 
                                initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, Period_or_Exact_Days__c, Recognition_Type__c, 
                                Residual_Amount__c, Residual_Amount_Type__c, Revenue_Recognition_End_Date__c,  Revenue_Recognition_Start_Date__c,
                                Enable_Manual_Forecast__c, Forecast_With_Zero_Value__c  
                                FROM RevRecRules__c ORDER BY Name LIMIT 2000];
        else 
            RevRecRules = [SELECT Id, name, Active__c, Default_Rule__c, Description__c, Divide_By__c, initial_amount__c, Milestone_Type__c,
                                initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, Period_or_Exact_Days__c, Recognition_Type__c, 
                                Residual_Amount__c, Residual_Amount_Type__c, Revenue_Recognition_End_Date__c,  Revenue_Recognition_Start_Date__c,
                                Enable_Manual_Forecast__c, Forecast_With_Zero_Value__c 
                                FROM RevRecRules__c WHERE Active__c = true ORDER BY Name LIMIT 2000];  
        
        List<RevRecRuleWrapper> result = new List<RevRecRuleWrapper>();
        Map<String, String> allDates = RevRecHelper.getAllOpportunityFieldsWithDateType();
        
        for(RevRecRules__c item : RevRecRules){
            RevRecRuleWrapper ruleDisplay = new RevRecRuleWrapper();
            ruleDisplay.rule = item;
            ruleDisplay.Revenue_Recognition_Start_Date_display = allDates.get(item.Revenue_Recognition_Start_Date__c);
            ruleDisplay.Revenue_Recognition_End_Date_display = allDates.get(item.Revenue_Recognition_End_Date__c);
            result.add(ruleDisplay);
        }
        return result;
    }
    
    public  RevRecRules__c getRecord () {return rule; }
    boolean showDetail = false;
    public boolean getShowDetail() {return showDetail;} 
    boolean showAmortizeDetail = false;
    boolean showMilestoneDetail = false;
    
    //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements 
    boolean showAmortizedMilestoneDetail = false;
    public boolean getShowAmortizedMilestoneDetail() {return showAmortizedMilestoneDetail;}
    
    //List of Select option foor line item number
    public List<SelectOption> lineItemForBlended {get; set;} 
    
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
    List<RevRecRuleMilestone__c> revRecRulesMilestones;
    
    public string ShowHideInActive {get; set;}
    public string StartStopCronJob {get; set;}
    
    public boolean showInActive  {get; set;}
    
    public List<RevRecRuleMilestone__c> getRevRecRulesMilestones() {
        return revRecRulesMilestones;
    }
    
    public void setRevRecRulesMilestones(List<RevRecRuleMilestone__c> abc) {
        RevRecRulesMilestones = abc;
    }
       
    /**** Code  added - 05/26/2015 - As per Blended revenue rule requirement **/
    /** START **/
    //Properties
    public boolean getShowBlendedRevenueDetail() {return showBlendedRevenueDetail;}
    public List<CategoryWrapper> listCategoryWrap {get;set;}
    public String categoryToBeSplit {get;set;}
    public String typeOfCategoryScreen {get;set;} //Either parent or Child
    public Id categoryParentId{get;set;}  
    
    //Variables
    Boolean isNewRule;
    Boolean showBlendedRevenueDetail = false; 
    Integer screenNum;
    Set<Id> setSplitCategoriesToBeDeleted;  
    String categoryToBeSplitParent;
    
    //Map is used to  hold parent with list of splits
    Map<Id, List<RevRecRuleCategory__c>> mapParentIdWithListOfSplits = new Map<Id, List<RevRecRuleCategory__c>>();
    
    //Set to hold all parent's id in split functonality
    Set<Id> setParentScreenCategoryIds = new Set<Id>();
    /** ** END ** **/
    
    //Code added - 11/03/2014
    RevRecProductRule__c overrideRule;
    public  RevRecProductRule__c getRRPRRecord () {return overrideRule; }
    public void setRRPRRecord(RevRecProductRule__c value) {
        overrideRule = value;            
    }
    
    /** Constructer **/
    public RevRecRuleController () { 
    	
        ShowHideInActive = 'Show Inactive Rules';
        showInActive = false; 
        indexString = '0'; 
        overrideRule = new RevRecProductRule__c();
        
        //Initilize - 04/04/2016 - As per to enable Split template functionality
        listSplitCategoryWrap = new List<CategoryWrapper>();
        isNewRule = false;
        screenNum = 0;
        categoryToBeSplitParent = '';
        setSplitCategoriesToBeDeleted = new Set<Id>();  
        mapParentIdWithListOfSplits = new Map<Id, List<RevRecRuleCategory__c>>(); 
        
        ruleIdToEdit = ApexPages.CurrentPage().getParameters().get('editRuleId');
               
        //Load defaults
        init();
        
         //Checking for Rule Id
        if(ruleIdToEdit != null) {
        	
        	showAmortizeDetail = false;
	        showMilestoneDetail = false;
	        showSingleTransDetail = false;
	        showAmortizedMilestoneDetail = false;
	        showBlendedRevenueDetail = false;
	        
        	GetRuleById(ruleIdToEdit);
        }
    }
    
    /** This method is used to hold and manage all the org wide defaults**/
    public void init() { 
        
        List<RevRecAppSetting__c> theSettingList = [select Id, Name, Is_Closed_Date_Validation__c, Opportunity_Stage__c, Opportunity_Type__c, Selected_Start_Date_Types__c, Selected_End_Date_Types__c, Time_of_Month_Selection_Types__c,  Certain_date_of_month__c, Certain_weekday__c, Certain_weekday_day__c, Certain_days_before_last_weekday__c, Certain_days_before_last_weekday_day__c, cron_job_id__c FROM  RevRecAppSetting__c  WHERE Name='AppSetting' LIMIT 1 ];
        if (theSettingList.Size() == 0 ) {
            theSetting =  new RevRecAppSetting__c(Name='AppSetting', Time_of_Month_Selection_Types__c = '1');            
        } else 
            theSetting = theSettingList[0];
        
        //Retrieving all dates of opportunity and product object  
        allDates = RevRecHelper.getAllOpportunityFieldsWithDateType();
        
        //Getting URL parameter
        String id = ApexPages.currentPage().getParameters().get('id');
        
        GetRuleById(id);
        
        if(theSetting.cron_job_id__c != null && theSetting.cron_job_id__c != '') 
            StartStopCronJob = 'Stop Calculate All Opportunities';
        else 
            StartStopCronJob = 'Start Calculate All Opportunities';
        
        //---------------- Amortize By -> Milestone Type
        //Setting Amortize by option 
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Milestone_Type__c',Constants.PERMISSION_UPSERT))
            rule.Milestone_Type__c = 'amount'; 
        
        //Initilize list of select option
        lineItemForBlended = new List<SelectOption>();           
        
        /** Code added - 06/04/2016 - As per to enable Split functionality on rule screen **/
        if(rule.Id != null) {
        	
        	//Query over Product Categories
            for(RevRecRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c,Level__c, Projected_Percent__c, Projected_Amount__c, 
                                                     Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                     Percent__c, Qty__c, Recognition_Type__c,Sub_Category_support__c, Projected_Qty__c, 
                                                     RevRecRule__c, RevRecRuleSplitCategory__c, Sequence__c,RevRecRuleSplitCategory__r.Ultimate_Parent__c,
                                                     (Select Id, Ultimate_Parent__c,Is_Split__c , Name, Line_Item__c,Sub_Category_support__c,Level__c,
                                                      Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                      Percent__c, Qty__c, Recognition_Type__c, Projected_Percent__c, Projected_Amount__c, Projected_Qty__c,
                                                      RevRecRule__c, RevRecRuleSplitCategory__c, RevRecRuleSplitCategory__r.Ultimate_Parent__c, Sequence__c From RevRecRuleCategorys1__r 
                                                      ORDER BY Sequence__c) FROM RevRecRuleCategory__c
                                                     Where RevRecRule__c =: rule.Id ORDER BY CreatedDate ASC]) {
                                
                //Checking for size of child //Populate map with values
                if(revCategory.RevRecRuleCategorys1__r.Size() > 0) {
                    mapParentIdWithListOfSplits.put(revCategory.Id, revCategory.RevRecRuleCategorys1__r);
                    if(Utility.checkFieldPermission(mapfieldRuleResult,'Is_Split_Categories__c',Constants.PERMISSION_UPSERT))
                        rule.Is_Split_Categories__c = true;
                }
                   
        	}
        }      
    }
    
    public List<SelectOption> getStartDateSelectOptions() {
        
        //List of select option
        List<SelectOption> options = new List<SelectOption>();
        
        //Add none in the list
        if(rule.Recognition_Type__c != Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)
        	options.add(new SelectOption('NONE', 'None'));
        
        //Checking for rule type and Manual as an option
        if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)
        	options.add(new SelectOption('MANUAL', 'Manual'));
        	
        //Temp list of string
        List<String> tempList = new List<String>();
        
        if (theSetting.Selected_Start_Date_Types__c != null)
            tempList = theSetting.Selected_Start_Date_Types__c.split(',');
        for(String s: tempList) {
            if (allDates.containsKey(s))
                options.add(new SelectOption(s,allDates.get(s)));
        }
        
        //Return list of select option
        return options;
    }
    
    public List<SelectOption> getEndDateSelectOptions() {
    	
    	//List of select option
        List<SelectOption> options = new List<SelectOption>();
        
        //Add none in the list
        options.add(new SelectOption('NONE', 'None'));
        
        //Checking for rule type and Manual as an option
        if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE)
        	options.add(new SelectOption('MANUAL', 'Manual'));
        
        //Temp list of string
        List<String> tempList = new List<String>();
        
        
        if (theSetting.Selected_End_Date_Types__c != null)
            tempList = theSetting.Selected_End_Date_Types__c.split(',');
        for(String s: tempList) {
            if (allDates.containsKey(s))
                options.add(new SelectOption(s,allDates.get(s)));
        }
        
        //Return list of select options
        return options;
    }
    
    //Code Added - 01/19/2015 - As per Milestone Date Automation Requirements:
    //Requirement 1:  Add Date variable support to the Milestone Rule Definition Screen
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
    
    public List<SelectOption> getRecognitionTypeOptions() {
    	
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Single Transaction','Single Transaction'));
        options.add(new SelectOption('Amortize','Amortize'));
        options.add(new SelectOption('Milestone','Milestone'));
        
        //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements 
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE, Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE));
        
        //Code added - 05/26/2015 - As per Blended Rule requirment
        options.add(new SelectOption(Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE, Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE));
        
        return options;
    }
    
    //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements 
    //Add select options list for Amortize By
     public List<SelectOption> getAmortizeByOptions() {
        List<SelectOption> options = new List<SelectOption>();       
        options.add(new SelectOption('Amount','Amount'));
        options.add(new SelectOption('qty','Quantity'));     
        return options;
    }   
    
    public List<SelectOption> getDividedByOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Period','Divided evenly by whole periods:'));
        options.add(new SelectOption('nonProrate','Prorate first and last periods by Exact Days'));
        options.add(new SelectOption('Prorate','Prorate first and last periods by Percentage'));
        
        return options;
    }   
 
    public List<SelectOption> getPeriodExactOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('period','By Whole Periods (for all other periods)'));
        options.add(new SelectOption('exact','By Exact Days (for all other periods)'));
        	
        return options;
    }
        
    public PageReference ChangeRecognitionTypeOptions() {
        showAmortizeDetail = false;
        showMilestoneDetail = false;
        showSingleTransDetail = false;
        showBlendedRevenueDetail = false;
        showAmortizedMilestoneDetail = false;
        if (rule.Recognition_Type__c == 'Amortize'){
            showAmortizeDetail = true;
            assignVisualBlocks ();
        } else if (rule.Recognition_Type__c == 'Milestone'){
            showMilestoneDetail = true;
            assignVisualBlocks ();
        } //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements
        else if (rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE){
            showAmortizedMilestoneDetail = true;
            if(Utility.checkFieldPermission(mapfieldRuleResult,'Period__c',Constants.PERMISSION_UPSERT)){
                rule.Period__c = 'Monthly';
            }
            assignVisualBlocks ();
        } else if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
        	showBlendedRevenueDetail = true;
            if(Utility.checkFieldPermission(mapfieldRuleResult,'Period__c',Constants.PERMISSION_UPSERT))
                rule.Period__c = 'Monthly';
            assignVisualBlocks ();
        }else {
            showSingleTransDetail = true;
        }
        return null;
    }

    public PageReference ChangeRecognitionPeriod() {
        showAmortizeDetail = true;
        assignVisualBlocks(); 
        return null;
    }

    private void assignVisualBlocks() {
        showByPeriodOrExactDetail = false;
        showDevideEvenlyDetail = false;
        showOffsetDetail = false;
        if (showMilestoneDetail) {
            
        } else {
            if (rule.Period__c == 'monthly'){
                showByPeriodOrExactDetail = true;
                showDevideEvenlyDetail = true;
                showOffsetDetail = true;
            } else if (rule.Period__c == 'weekly'){
                showOffsetDetail = true;
            } else if (rule.Period__c == 'quarterly'){
                showOffsetDetail = true;
            } else if (rule.Period__c == 'yearly'){
                showOffsetDetail = true;
            } else if (rule.Period__c == 'daily'){
                showOffsetDetail = true;
            } 
        }
    }   
    
    public PageReference cancel() {  showDetail = false;      
    	
    	//Code added - 04/04/2016 - As per split functionality
    	//Checking if rule was inserted before allocaton and the cancelled
    	if(isNewRule) {
    		
    		//Query to fetch the newly created record while spliting
    		List<RevRecRules__c> defaultRule = [SELECT id from RevRecRules__c WHERE Id =: rule.Id LIMIT 1];
    		
    		//Checking for the size and then delete rule
    		if(defaultRule.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecRules__c')))
    			delete defaultRule;
    	}
    	
    	//Checking if it comes from Rule Assignment 
    	if (String.isNotBlank(ruleIdToEdit)) {
    		PageReference pf = new PageReference('/apex/AppRopozSLN__RevRecConfig?tab=1');
    		return pf;
    	}else
    		return null;
    	
    	return null;
    	
    }
    public PageReference save() { 
        String msg = '';
        
        RevRecRuleWrapper ruleDisplay = new RevRecRuleWrapper();
        
        //Code added - 02/05/2015 - Add Error message while start date or end date is not set for Amortized milstone rule
        if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE)  {
            if(Utility.checkFieldPermission(mapfieldRuleResult,'Milestone_Type__c',Constants.PERMISSION_UPSERT))
                rule.Milestone_Type__c = 'amount';
            //Check for Dates not null 
            if(string.isBlank(rule.Revenue_Recognition_End_Date__c) || string.isBlank(rule.Revenue_Recognition_Start_Date__c)) {                    
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, label.SELECT_START_AND_END_DATE));
                return null;
            }   
        }
        
        //Code added on 11/25/2016 - New Enhancement - Verify that a rule names are unique. New rule name checks against already existing rule names. 
        //List to hold existing rule
        List<RevRecRules__c> existingRule;
        if(rule.Id != null)
        	existingRule = [Select Id, Revenue_Recognition_Start_Date__c, Revenue_Recognition_End_Date__c from RevRecRules__c where Name =: rule.Name AND Id !=: rule.Id LIMIT 1];
        else
       		existingRule = [Select Id from RevRecRules__c where Name =: rule.Name LIMIT 1];
        
        //Check if rule exist
        if(existingRule.size() > 0) {
       		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Constants.RULE_ALREADY_EXIST));
       		return null;	
        }
        
        if(rule.Divide_By__c == 'Prorate') {
            if(Utility.checkFieldPermission(mapfieldRuleResult,'Start_Percentage__c',Constants.PERMISSION_UPSERT)){
                if(rule.Start_Percentage__c == null)
                    rule.Start_Percentage__c = 0.00;
            }
            
            if(Utility.checkFieldPermission(mapfieldRuleResult,'End_Percentage__c',Constants.PERMISSION_UPSERT)){
                if(rule.End_Percentage__c == null)
                    rule.End_Percentage__c = 0.00;
            }
            
            //Code is added on 05/05/2017 for urgent fixes on Amortize and Amortized Milestone
	        //Check for rule start and end % total not exeed 100
	        if(rule.Start_Percentage__c != null || rule.End_Percentage__c != null) {
	        	
	        	Decimal totalPercentage = rule.Start_Percentage__c + rule.End_Percentage__c;
	        	
	        	if(totalPercentage != 100.00) {
		        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Constants.RULE_START_AND_END_PERCENTAGE_NOT_MORE_THAN_100));
		       		return null;
	        	}
	        }
         }
         
         //Code Added - 06/20/2018 - If else condition added to make changes in dates when rule is updated
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Revenue_Recognition_Start_Date__c',Constants.PERMISSION_UPSERT) && Utility.checkFieldPermission(mapfieldRuleResult,'Revenue_Recognition_End_Date__c',Constants.PERMISSION_UPSERT)){
            if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_MILESTONE) {
                rule.Revenue_Recognition_Start_Date__c = null;
                rule.Revenue_Recognition_End_Date__c = null;
            } else if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION) {
                rule.Revenue_Recognition_End_Date__c = null;
            } else if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
                rule.Revenue_Recognition_Start_Date__c = null;
                rule.Revenue_Recognition_End_Date__c = null;
            }
        }
        if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecRules__c')){
            upsert(rule);
        }
        
        if (rule.Recognition_Type__c == 'Milestone') {
        
            Decimal totalPercent = 0;
            Date mileStoneDate;
            Decimal totalAmount = 0;
            Decimal totalQty = 0;
            
            for(RevRecRuleMilestone__c item : revRecRulesMilestones) {
                
                if (item.Actual_Percent__c != null) {
                    totalPercent += item.Actual_Percent__c;
                }
                
                if(item.RevRecRule__c == null)
                	item.RevRecRule__c = rule.Id;
                	
	            if(item.Actual_Percent__c != null) {
	            	if ((totalPercent- 100) > 0.0001)
	                	msg += 'Total percentage is more than 100%';
	            } 
	        
	            if (msg != '')   {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                    return null;
	            }
            }
            
            List<RevRecRuleMilestone__c> allMilestoneInDB = [SELECT Id, name FROM RevRecRuleMilestone__c WHERE RevRecRule__c = :rule.Id];
            List<RevRecRuleMilestone__c> deletedMilestone = new List<RevRecRuleMilestone__c>();
            for(RevRecRuleMilestone__c itemInDB : allMilestoneInDB) {
                Boolean itemExistInWorkingList = false;
                for (RevRecRuleMilestone__c itemInWorkingList : revRecRulesMilestones) {                   
                    if (itemInWorkingList.Id != null && itemInWorkingList.Id == itemInDB.id) {
                            itemExistInWorkingList = true;
                            break;
                    }
                }
                if (!itemExistInWorkingList) 
                  	deletedMilestone.add(itemInDB);
                
            }
            if (deletedMilestone.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecRuleMilestone__c')))
                delete(deletedMilestone);

            upsert(revRecRulesMilestones);
        } else {
            List<RevRecRuleMilestone__c> allMilestoneInDB = [SELECT Id, name FROM RevRecRuleMilestone__c WHERE RevRecRule__c = :rule.Id];
            if(allMilestoneInDB.size() >0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecRuleMilestone__c'))) 
                delete (allMilestoneInDB);
        }
        
        //Code added - 05/27/2015 - As per blended Revenue  requirement
        //Checking for the Recognition type :IF Blended then do this
        if(rule.Recognition_Type__c == constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
        	
        	//Decimal to hold totle percent
        	Decimal totalPercent = 0.00;
            Decimal totalProjectedPercent = 0.00;
        	
        	//List of category to be upsert (New / Edit Rule)
        	List<RevRecRuleCategory__c> listCategoryToBeUpsert = new List<RevRecRuleCategory__c>();
        
        	//loop through wrapper class
        	for(CategoryWrapper wrap : listCategoryWrap) {
        		        		
        		if(wrap.category1.Percent__c != null)
        			totalPercent += wrap.category1.Percent__c;
        		if(wrap.category1.Projected_Percent__c != null)
        			totalProjectedPercent += wrap.category1.Projected_Percent__c;
        		
        		//Add rule on Category
                if(Utility.checkFieldPermission(mapfieldCatResult,'RevRecRule__c',Constants.PERMISSION_UPSERT))
                    wrap.category1.RevRecRule__c = rule.Id;
        		
        		//Checking  for end date : If End date not null then Set it to Amortize else Single Transaction
                if(Utility.checkFieldPermission(mapfieldCatResult,'Recognition_Type__c',Constants.PERMISSION_UPSERT)){
                    if(string.isNotBlank(wrap.category1.Category_End_Date__c) && wrap.category1.Category_End_Date__c != 'None' )
                        wrap.category1.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
                    else
                        wrap.category1.Recognition_Type__c = Constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
                }
                
                if(Utility.checkFieldPermission(mapfieldCatResult,'Level__c',Constants.PERMISSION_UPSERT))
                    wrap.category1.Level__c = 0;
                
        		//Add wrapper catgory into list
        		listCategoryToBeUpsert.add(wrap.Category1);
        	}
        	
        	//Checking  for list size and upsert the Category
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecRuleCategory__c')){
                if(listCategoryToBeUpsert.size() > 0)
                    upsert listCategoryToBeUpsert; 
            }
        }
        
        showDetail = false;
        return null;    
    }   
    
    public PageReference toggleShowHideInActive() {
        showInActive = !showInActive;
        if (showInActive)
            ShowHideInActive = 'Hide Inactive Rules';
        else
            ShowHideInActive = 'Show Inactive Rules';
        
        return null;
        
    }
    
    public PageReference toggleStartStopCronJob() {
        if (theSetting.cron_job_id__c != null && theSetting.cron_job_id__c != '') {
            List<CronTrigger> cronList =  ( [select Id, CronExpression from CronTrigger where id = :theSetting.cron_job_id__c limit 1]);
            if (cronList.size() > 0) {
                System.abortJob(cronList[0].Id);
            }
            if(Utility.checkFieldPermission(mapfieldAppSetResult,'cron_job_id__c',Constants.PERMISSION_UPSERT))
                theSetting.cron_job_id__c = '';
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPDATE, 'RevRecAppSetting__c')){
                update(theSetting);
            }
            StartStopCronJob = 'Start Calculate All Opportunities';
        } else {
            String CRON_EXP = '0 0 * * * ?';
            RevRecScheduler sch = new RevRecScheduler();
            string cronID = system.schedule('AppRopoz Calculate All Opportunites Cron Job', CRON_EXP, sch);
            
            if(Utility.checkFieldPermission(mapfieldAppSetResult,'cron_job_id__c',Constants.PERMISSION_UPSERT))
                theSetting.cron_job_id__c = cronID;
            if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecAppSetting__c')){
                upsert(theSetting);
            }
            StartStopCronJob = 'Stop Calculate All Opportunities';
        }

        return null;
        
    }   
    
    public PageReference create() {
        rule = new RevRecRules__c();
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Recognition_Type__c',Constants.PERMISSION_UPSERT))
            rule.Recognition_Type__c = 'Single Transaction';
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Residual_Amount__c',Constants.PERMISSION_UPSERT))
            rule.Residual_Amount__c = 0;
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Residual_Amount_Type__c',Constants.PERMISSION_UPSERT))
            rule.Residual_Amount_Type__c = 'Amount';
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Active__c',Constants.PERMISSION_UPSERT))
            rule.Active__c = true;
        //rule.Amortize_By__c = 'Amount';
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Period__c',Constants.PERMISSION_UPSERT))
            rule.Period__c = 'monthly';
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Divide_By__c',Constants.PERMISSION_UPSERT))
            rule.Divide_By__c = 'Period';
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Period_or_Exact_Days__c',Constants.PERMISSION_UPSERT))
            rule.Period_or_Exact_Days__c = 'period';
        if(Utility.checkFieldPermission(mapfieldRuleResult,'Milestone_Type__c',Constants.PERMISSION_UPSERT))
            rule.Milestone_Type__c = 'amount';
        showAmortizeDetail = false;
        showMileStoneDetail = false;
        showDetail = true;
        showSingleTransDetail = true;
        revRecRulesMilestones = new List<RevRecRuleMilestone__c>(); 
        listCategoryWrap = new List<CategoryWrapper>();
        return null;
    }   
    
    private void GetRuleById(String id){
        
        //Code modified - 05/27/2015 - As per Blended Revenue requirement
        //Inline query for Category
        //Code- modified - 10/31/2014 - As per Amortized Milestone Rule Requirements
        //Add "Amortize_By__c" field in query
        //Code modified - 04/27/2016 - As per start and end date percentage
        List<RevRecRules__c> ruleList = [SELECT Id, name, Active__c, Default_Rule__c, Description__c, Divide_By__c, initial_amount__c, 
                                            initial_amount_type__c, Offset_Period__c,  offset_type__c,Period__c, Period_or_Exact_Days__c, 
                                            Recognition_Type__c, Residual_Amount__c, Residual_Amount_Type__c, Revenue_Recognition_End_Date__c, 
                                            Revenue_Recognition_Start_Date__c, /*Amortize_By__c,*/Milestone_Type__c,Start_Percentage__c ,End_Percentage__c,
                                            Enable_Manual_Forecast__c, Forecast_With_Zero_Value__c,
                                            (SELECT Id,  Name, RevRecRule__c, Milestone_Sequence__c, Milestone_Name__c, Percent__c,Amount__c,
                                                Qty__c, Projected_Percent__c, Projected_Amount__c, Actual_Percent__c, Actual_Amount__c, Projected_Qty__c,
                                                //Code added- 10/19/2015 - Milestone_Date_Source__c added in Query - 
                                                //As per Milestone Date Automation Requirement
                                                Milestone_Date_Source__c
                                                From RevRecRuleMilestones__r ORDER BY Milestone_Sequence__c),
                                                //As per Blended revenue recognition
                                                //Added a new field in the query - Sub_Category_support__c
                                               (SELECT Id,  Name, RevRecRule__c, Sequence__c,Is_Split__c ,Percent__c, Amount__c, Category_Type__c,Level__c,
                                                Category_End_Date__c , Category_Start_Date__c, Recognition_Type__c, Line_Item__c, Qty__c ,Sub_Category_support__c,
                                                Projected_Percent__c, Projected_Amount__c, Projected_Qty__c
                                                From RevRecRuleCategorys__r WHERE RevRecRuleSplitCategory__c = null ORDER BY Sequence__c)
                                            from RevRecRules__c where id = :id];
        if (ruleList.Size() == 0){ 
            rule = new RevRecRules__c();
            revRecRulesMilestones = new List<RevRecRuleMilestone__c>();
            
            //Code added - 05/27/2015 - As per blended revenue requirment
            listCategoryWrap = new List<CategoryWrapper>();
        }else {
            rule = ruleList[0];
            revRecRulesMilestones = rule.RevRecRuleMilestones__r;    
            showDetail = true;
            
            //Inililize list of wrapper
            listCategoryWrap = new List<CategoryWrapper>();
            
            //Code added - 05/27/2015 -  As per Blended revenue requirement
            if(rule.RevRecRuleCategorys__r.size() > 0) {
            	
	            //Loop through all category's
	            for(RevRecRuleCategory__c catgry : rule.RevRecRuleCategorys__r) {
	            	
	            	lineItemForBlended = new List<SelectOption>();
	            	
	            	for(Integer i=0 ; i< catgry.Sequence__c ; i++)
	            		lineItemForBlended.add(new SelectOption(String.valueOf(i) , String.valueOf(i)));
	            	
	            	listCategoryWrap.add(new CategoryWrapper(catgry, lineItemForBlended, false));
	            }
            }
        }
        
        if (rule.Recognition_Type__c == 'Amortize'){
            showAmortizeDetail = true; 
            assignVisualBlocks ();
        } else if (rule.Recognition_Type__c == 'Milestone'){
            showMilestoneDetail = true;
            assignVisualBlocks ();
        } 
        //Code added - 10/31/2014 - As per Amortized Milestone Rule Requirements
        else if (rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE) {
            showAmortizedMilestoneDetail = true;
            assignVisualBlocks ();
        } else if(rule.Recognition_Type__c == Constants.RULE_RECOGNITION_TYPE_BLENDED_REVENUE) {
        	showBlendedRevenueDetail = true;
            if(Utility.checkFieldPermission(mapfieldRuleResult,'Period__c',Constants.PERMISSION_UPSERT))
                rule.Period__c = 'Monthly';
            
            assignVisualBlocks ();
            
            //Query over Product Categories
            //Added a new field in the query - Sub_Category_support__c
            for(RevRecRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c,
                                                                        Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                        Percent__c, Qty__c, Recognition_Type__c,Sub_Category_support__c,Level__c,
                                                                        RevRecRule__c, RevRecRuleSplitCategory__c, Sequence__c,RevRecRuleSplitCategory__r.Ultimate_Parent__c,
                                                                        (Select Id, Ultimate_Parent__c,Is_Split__c , Name, Line_Item__c,Level__c,
                                                                        Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                        Percent__c, Qty__c, Recognition_Type__c,Sub_Category_support__c,
                                                                        Projected_Percent__c, Projected_Amount__c, Projected_Qty__c,
                                                                        RevRecRule__c, RevRecRuleSplitCategory__c, RevRecRuleSplitCategory__r.Ultimate_Parent__c, Sequence__c From RevRecRuleCategorys1__r 
                                                                        ORDER BY Sequence__c) FROM RevRecRuleCategory__c
                                                                        Where RevRecRule__c =: rule.Id ORDER BY CreatedDate ASC]) {
                                
                //Checking for size of child //Populate map with values
                if(revCategory.RevRecRuleCategorys1__r.Size() > 0) 
                    mapParentIdWithListOfSplits.put(revCategory.Id, revCategory.RevRecRuleCategorys1__r);
            }
        }else {
            showSingleTransDetail = true;

        }
    }
    
    public PageReference edit ()    {
        PageReference pr = ApexPages.currentPage();
        Id id = pr.getParameters().get('id');
        showAmortizeDetail = false;
        showMilestoneDetail = false;
        showSingleTransDetail = false;
        
        //Code added - 10/31/2014 -  As per Amortized Milestone Rule Requirements 
        showAmortizedMilestoneDetail = false;
        
        //Code added - 05/27/2015 -  As per Blended Revenue Requirement
        showBlendedRevenueDetail = false;
        
        GetRuleById(id);
        //pr.setAnchor('detailAnchor');
        return null;
    }
    
    public PageReference deleteRule ()  {
        PageReference pr = ApexPages.currentPage();
        string id = pr.getParameters().get('id');
        List<RevRecRules__c> rule = [select Id, name from RevRecRules__c where id = :id];
        
        if(rule.size() > 0)
        	delete(rule);
        
        //pr.setAnchor('detailAnchor');
        return null;
    }

	//This method is used to 
    public void addMilestone () {
    	    	
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
        	highestRowCounter =  revRecRulesMilestones.size();
     
        //Instance of Miles
        RevRecRuleMilestone__c mile  = new RevRecRuleMilestone__c(Milestone_Sequence__c = highestRowCounter + 1, Milestone_Name__c = '');
        
        //Set counter +1 after the new row addition Milestones
        for(RevRecRuleMilestone__c mS : revRecRulesMilestones) {
        	
        	//Checking for next rows after new and set +1 
        	if(mS.Milestone_Sequence__c > highestRowCounter) {
        		mS.Milestone_Sequence__c += 1;
        	}
        }   
        //Add mile stone into list     
        revRecRulesMilestones.add(mile);
        
		//Map to hold RevRecRuleMilestone__c record with sequence
        Map<Integer, RevRecRuleMilestone__c> mapSeqWithMiles = new   Map<Integer, RevRecRuleMilestone__c>();
        
        //Loop over List category wrapper
        for(RevRecRuleMilestone__c mStone : revRecRulesMilestones) {
        	mapSeqWithMiles.put(Integer.valueOf(mStone.Milestone_Sequence__c)  , mStone);
        }
        
        //List of Sequence
        List<Integer> listSequences = new List<Integer>();
        listSequences.addAll(mapSeqWithMiles.keySet());
        listSequences.sort();
        
        //Clear List of milestones	
        revRecRulesMilestones.clear();
        
        //Loop over sequences
        for(Integer seq  : listSequences) 
        	revRecRulesMilestones.add(mapSeqWithMiles.get(seq));   
    }
    
    public void removeMilestone () {
    	
    	//Set to hold sequence and Name of category 
    	Set<Integer> setSequences = new Set<Integer>();
    	Set<String> setString = new Set<String>();
    	
    	//Map to hold Wrapper with sequence
    	Map<Integer, RevRecRuleMilestone__c> mapSeqWithMiles = new Map<Integer, RevRecRuleMilestone__c>();
    	
    	//Loop over list
    	for(RevRecRuleMilestone__c mile : revRecRulesMilestones) 
    		mapSeqWithMiles.put(Integer.valueOf(mile.Milestone_Sequence__c), mile);
        //Loop over wrapper class and checking for the selected record 
    	if(String.isNotBlank(indexString)) {
	        for(String str : indexString.split(',')) {
	        	setSequences.add(Integer.valueOf(str));
	        	setString.add(revRecRulesMilestones[Integer.valueOf(str)].Name);
	        }   
    	}else {
    		setSequences.add(Integer.valueOf(revRecRulesMilestones.size() - 1));
	        setString.add(revRecRulesMilestones[revRecRulesMilestones.size() - 1].Name);
    	}
	        
        //Checking for current sequence size and remove sequence from series
        if (setSequences.size() > 0) {
        	for(Integer seq : setSequences)
        		mapSeqWithMiles.remove(seq+1);
        }
        
        //Initlize category wrap and assign temp list to wrapper
        revRecRulesMilestones = new List<RevRecRuleMilestone__c>();
        revRecRulesMilestones = mapSeqWithMiles.values();
        Integer j = 1;
        
        //Loop over Category wrapper
        for(RevRecRuleMilestone__c mile : revRecRulesMilestones) {
        	mile.Milestone_Sequence__c = j; 
        	mile.Name = revRecRulesMilestones[j-1].Name;
        	j++;
        }
       
       //Query to fetch the category record to be delete
        List<RevRecRuleMilestone__c> ruleMileToDelete = [Select Id From RevRecRuleMilestone__c WHERE Name IN: (setString) AND RevRecRule__c =:rule.Id];
        //Delete Rule category
        if(ruleMileToDelete.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecRuleMilestone__c')))
        	delete ruleMileToDelete;
    }
    
    //Code modified - 12/2/2014 - Change Revenue % to %
    public List<SelectOption> getMilestoneOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('percent','%'));
        options.add(new SelectOption('amount','Amount'));
        options.add(new SelectOption('qty','Qty'));
        return options;
    }
    
    //Code added - 05/27/2015 - As per Blended revenue requirement
    public List<SelectOption> getBlendedOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Percent','PERCENT'));
        options.add(new SelectOption('Amount','AMOUNT'));
        options.add(new SelectOption('Qty','QUANTITY'));
        return options;
    }
    
    /**         ~~~~ Code commented - 11/03/2014 ~~~~
     *  @description    :   This method is used just for interation with controller of page.
     *
     *  @param          :
     *
     *  @retrun         :   PageReference
     **/
     public PageReference ChangeMilestoneType() {
        return null;
    }
    
    /**         ~~~~ Code commented - 11/13/2017 ~~~~
     *  @description    :   This method is used just for interation with controller of page.
     *
     *  @param          :
     *
     *  @retrun         :   PageReference
     **/
     public PageReference ChangeMilestoneProjectedType() {
        return null;
    }
    
    //Code added - 11/03/2014
    //milestone total percentage or amount
    public String getMilestoneTotal() {
        
        //String results
        string result = '';
        
        //Checking for mile stone type 
        if (string.isNotBlank(overrideRule.Milestone_Type__c) && overrideRule.Milestone_Type__c.equalsIgnoreCase('amount')) {
            
            Decimal total = 0.00;
            for(RevRecRuleMilestone__c item : revRecRulesMilestones){
                if (item.amount__c != null)
                    total += decimal.valueOf(Double.valueOf(item.amount__c)).setScale(2);      
            }
            result =  total + ' Remaining';
        } else if (string.isNotBlank(overrideRule.Milestone_Type__c) && overrideRule.Milestone_Type__c.equalsIgnoreCase('qty')) {
            Decimal total = 0;
            for(RevRecRuleMilestone__c item : revRecRulesMilestones){
                if (item.qty__c != null)
                    total += decimal.valueOf(Double.valueOf(item.qty__c)).setScale(2);
            }
            result =  total + ' Remaining';
        } else {
            //Code modified - 12/12/2014- Change data type from Integer -> Decimal
            Decimal total = 0.00;
            for(RevRecRuleMilestone__c item : revRecRulesMilestones){
                
                //Code Modified - 12/12/2014 - Change Integer.ValueOf -> decimal.valueOf(Double.ValueOf()).setScale()
                if (item.Actual_percent__c != null)
                    total += decimal.valueOf(Double.valueOf(item.Actual_percent__c)).setScale(2);
            }
            result =  total + '%' ;
        }
        
        return result;
    }
    
      public pageReference saveMilesOnBlur() {
          if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecRules__c')){
              upsert rule;
          }
      	
      	string msg = '';
      	 if (rule.Recognition_Type__c == 'Milestone') {
      	 	
            Decimal totalPercent = 0;
            Date mileStoneDate;
            
            //Loop through milestones
            for(RevRecRuleMilestone__c item : revRecRulesMilestones) {
           		
           		if (item.RevRecRule__c == null)
                        item.RevRecRule__c = rule.Id;                        
            }
            
            if ((totalPercent- 100) > 0.0001)
                msg += 'Total percentage is more than 100%';
      	 }
      	 
        if (msg != '')   {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, msg ));
                return null;
        }
     	 
     	//Checking for list size
     	if(revRecRulesMilestones.size() >0 )
     		upsert revRecRulesMilestones;   
     		
     	return null;
     }   
    
    /**
     *	@description	:	This method is used to add row on Rule screen.
     *
     *	@args			:
     *
     *	@return			:	Void
    **/
    public void addCategory ()    {
    	
    	//Current sequence
    	Integer currentSequence = 0;
    	
    	//Assign current sequence start from previos sequence
        //currentSequence = listCategoryWrap.Size() > 0 ? listCategoryWrap.Size() : 0;
        
        //Loop over Category wrapper
        for(CategoryWrapper cWrap : listCategoryWrap) {
        	
        	//Checking for selected category
        	if(cWrap.isSelected) {
        		currentSequence = 0;
        		currentSequence = Integer.valueOf(cWrap.category1.Sequence__c);
        	}        	
        }
        
        //If currenct dequence is 0 then set this to high sequence
        if(currentSequence == 0)
        	currentSequence = listCategoryWrap.size();
        
        //Create new category record
        RevRecRuleCategory__c category1 = new RevRecRuleCategory__c(Sequence__c = currentSequence + 1, Name = '');
        
        //Loop over Category wrapper
        for(CategoryWrapper cWrap : listCategoryWrap) {
        	if(cWrap.category1.Sequence__c > currentSequence) {
                if(Utility.checkFieldPermission(mapfieldCatResult,'Sequence__c',Constants.PERMISSION_UPSERT))
                    cWrap.category1.Sequence__c += 1; 
        		lineItemForBlended = new List<SelectOption>();
        		
	            for(Integer i=0 ; i< cWrap.category1.Sequence__c ; i++)
	            	lineItemForBlended.add(new SelectOption(String.valueOf(i) , String.valueOf(i)));
	            
	            cWrap.lineItemForBlended = lineItemForBlended;
        	}
        } 
        
        
        //Inilitize list of select option
        lineItemForBlended = new List<SelectOption>();        
        
    	for(Integer i=0; i<= currentSequence ; i++) {
	        
	        //Popualte line item
	    	lineItemForBlended.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
    	}
       
        //Add new RevRecRule category row on page
        listCategoryWrap.add(new CategoryWrapper (category1, lineItemForBlended, false));
        
        //Map to hold wrapper record with sequence
        Map<Integer, CategoryWrapper> mapSeqWithCatWrap = new   Map<Integer, CategoryWrapper>();
        
        //Loop over List category wrapper
        for(CategoryWrapper cWrap : listCategoryWrap) {
        	cWrap.isSelected = false;
        	mapSeqWithCatWrap.put(Integer.valueOf(cWrap.category1.Sequence__c)  , cWrap);
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
     *	@description	:	This method is used to remove  row from Rule screen.
     *
     *	@args			:
     *
     *	@return			:	Void
    **/
    public void removeCategory () {
    	
    	//Set to hold sequence and Name of category 
    	Set<Integer> setSequences = new Set<Integer>();
    	Set<String> setString = new Set<String>();
    	
    	//Map to hold Wrapper with sequence
    	Map<Integer, CategoryWrapper> mapSeqWithWrap = new Map<Integer, CategoryWrapper>();
    	
    	for(CategoryWrapper catWrap : listCategoryWrap) 
    		mapSeqWithWrap.put(Integer.valueOf(catWrap.category1.sequence__c), catWrap);
    	
        //Loop over wrapper class and checking for the selected record 
        for(CategoryWrapper CatWrapper : listCategoryWrap) {
        	
        	//Checking for Selected value
        	if(CatWrapper.isSelected) {
        		setSequences.add(Integer.valueOf(CatWrapper.category1.Sequence__c));
        		setString.add(CatWrapper.category1.Name);
        	}
        }
        
        if(setSequences.size() == 0 && setString.size() == 0)   {
        	
        	setSequences.add(Integer.valueOf(listCategoryWrap[listCategoryWrap.size() - 1].category1.Sequence__c));
        	setString.add(listCategoryWrap[listCategoryWrap.size() - 1].category1.Name);
        }
        
        //Checking for current sequence size and remove sequence from series
        if (setSequences.size() > 0) {
        	for(Integer seq : setSequences)
        		mapSeqWithWrap.remove(seq);
        }
        
        //Initlize category wrap and assign temp list to wrapper
        listCategoryWrap = new List<CategoryWrapper>();
        listCategoryWrap = mapSeqWithWrap.values();
        Integer j = 1;
        
        //Loop over Category wrapper
        for(CategoryWrapper cWrap : listCategoryWrap) {
        	cWrap.category1.Sequence__c = j; 
        	
        	//Inilitize list of select option
            List<SelectOption> lineItemForBlended = new List<SelectOption>();  
        	for(Integer i=1 ; i<= j ; i++) {
        		lineItemForBlended.add(new SelectOption(String.valueOf(i-1), String.valueOf(i-1)));
        	}
        	cWrap.lineItemForBlended = lineItemForBlended;
        	cWrap.isSelected = false;
        	j++;
        }
       
       //Query to fetch the category record to be delete
        List<RevRecRuleCategory__c> ruleCatsToDelete = [Select Id From RevRecRuleCategory__c WHERE Name IN: (setString) AND RevRecRule__c =:rule.Id];
        
        //Delete Rule category
        if(ruleCatsToDelete.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecRuleCategory__c')))
        	delete ruleCatsToDelete;
    }
     
     /** Wrapper class to hold the rule category **/
     public class CategoryWrapper {
     	
     	//Variables 
     	public RevRecRuleCategory__c category1 {get; set;}
     	public List<SelectOption> lineItemForBlended {get;set;}
     	public boolean isSelected {get;set;}
     	
     	//Constructer
     	public CategoryWrapper(RevRecRuleCategory__c category1, List<SelectOption> lineItemForBlended, Boolean isSelected) {
     		
     		this.category1 = category1;
     		this.lineItemForBlended = lineItemForBlended;
     		this.isSelected = isSelected;
     	}
     }
     
     /** **** **** Code added  - 04/02/2016 -  As per BUG #19 **** **** **/
     /**** BUG #19 Predefined Splits on the Blended Revenue Template ****/
     /**
      *	@description	:	This method is used to do the Splits while clicking on the Allocate button from the blended screen.
      *
      *	@args			:	-
      *
      *	@return			:	-
     **/
     public void doSplitCategories() {
     	
     	//List of select options 
        List<SelectOption> options = new List<SelectOption>();
        
     	//Checking if rule is already inserted or not
     	if(rule.Id == null) {
     		isNewRule = true;
            if(Utility.checkFieldPermission(mapfieldRuleResult,'Is_Split_Categories__c',Constants.PERMISSION_UPSERT))
                rule.Is_Split_Categories__c = true;
            if(Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecRules__c')){
                insert rule;
            }
     	}
     	 
     	 //Checking for Window either parent or Child
        if(typeOfCategoryScreen == constants.SPLIT_SCREEN_TYPE_PARENT) {
        	
        	screenNum = 1;
        	
        	 //Initilize value
            listSplitCategoryWrap = new List<CategoryWrapper>();	
            categoryToBeSplitParent = categoryToBeSplit;
            
             //Temp list to be inserted'
            List<RevRecRuleCategory__c> tempParentListToInserted = new List<RevRecRuleCategory__c>();
            
            //Loop over list of parent wrapper
            for(CategoryWrapper parentWrap : listCategoryWrap) { 
                
                //Checking for null
                if(parentWrap.category1.Id == null) {
                    if(Utility.checkFieldPermission(mapfieldCatResult,'RevRecRule__c',Constants.PERMISSION_CREATE))
                        parentWrap.category1.RevRecRule__c = rule.Id;
                    if(Utility.checkFieldPermission(mapfieldCatResult,'Level__c',Constants.PERMISSION_CREATE))
                        parentWrap.category1.Level__c = 0;
                    tempParentListToInserted.add(parentWrap.category1);
                }
            }
              
            //Checking for list size and insert parent categories
            if(Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecRuleCategory__c')){
                if(tempParentListToInserted.size() > 0)
                    insert tempParentListToInserted;
            }
            
            //Splitted Category     
            RevRecRuleCategory__c splittedCategories = listCategoryWrap[Integer.valueOf(categoryToBeSplit) - 1].category1;
            
             //Loop over list of parent wrapper
            for(CategoryWrapper parentWrap : listCategoryWrap) { 
                
                //Checking for null
                if(parentWrap.category1.Id != null)
                    setParentScreenCategoryIds.add(parentWrap.category1.Id);
            }
            
            //Instance of rule category - to be display on the popup screen
            RevRecRuleCategory__c splittedCategories1 = new RevRecRuleCategory__c();
            
             //Assign Split Categories values to new instance
            if(Utility.checkFieldPermission(mapfieldCatResult,'Name',Constants.PERMISSION_UPSERT))
                splittedCategories1.Name = splittedCategories.Name;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Line_Item__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Line_Item__c = splittedCategories.Line_Item__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Amount__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Amount__c = splittedCategories.Amount__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Category_End_Date__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Category_End_Date__c = splittedCategories.Category_End_Date__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Category_Start_Date__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Category_Start_Date__c = splittedCategories.Category_Start_Date__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Category_Type__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Category_Type__c = splittedCategories.Category_Type__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Percent__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Percent__c = splittedCategories.Percent__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Qty__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Qty__c = splittedCategories.Qty__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Projected_Percent__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Projected_Percent__c = splittedCategories.Projected_Percent__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Projected_Qty__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Projected_Qty__c = splittedCategories.Projected_Qty__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Projected_Amount__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Projected_Amount__c = splittedCategories.Projected_Amount__c;
            if(Utility.checkFieldPermission(mapfieldCatResult,'RevRecRuleSplitCategory__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.RevRecRuleSplitCategory__c = splittedCategories.Id;
            if(Utility.checkFieldPermission(mapfieldCatResult,'RevRecRule__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.RevRecRule__c = rule.Id;
            if(Utility.checkFieldPermission(mapfieldCatResult,'Ultimate_Parent__c',Constants.PERMISSION_UPSERT))
                splittedCategories1.Ultimate_Parent__c = splittedCategories.Id;
            splittedCategories1.Level__c = 1;
            
            lineItemRow = String.ValueOf(splittedCategories.Sequence__c); 
            
             //Query to get the splitted Categories if any categories exist for main Category
            List<RevRecRuleCategory__c> splitCatgs = [Select Id, Name, Is_Split__c ,Line_Item__c, Amount__c, Category_End_Date__c, Category_Start_Date__c, 
            														    Category_Type__c,Ultimate_Parent__c,Sub_Category_support__c,
                                                                        Percent__c, Qty__c, Recognition_Type__c,Level__c,
                                                                        RevRecRule__c, RevRecRuleSplitCategory__c, Sequence__c,
                                                                        RevRecRuleSplitCategory__r.Ultimate_Parent__c From RevRecRuleCategory__c
                                                                        Where RevRecRuleSplitCategory__c =: splittedCategories.Id];
            
            //Checking if no any existig split exist
            if(splitCatgs.size() == 0) {
                
                //Initilize 
                options.add(new SelectOption('0', '0'));
                splittedCategories1.sequence__c = 1;
                            
                //Add values in wrapper list
                listSplitCategoryWrap.add(new CategoryWrapper(splittedCategories1, options, false));
            }else {
                 
                //Loop over existing categories
                for(RevRecRuleCategory__c prdCategory : splitCatgs) {
                    
                    //Initilize list of select options
                    options = new List<SelectOption>();
                     
                    //Loop over category sequence 
                    for(Integer j=0 ; j< prdCategory.Sequence__c ; j++)
                        options.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
                    
                    if(Utility.checkFieldPermission(mapfieldCatResult,'Level__c',Constants.PERMISSION_UPSERT))
                        prdCategory.Level__c = 1;
                    
                    //Populate Category wrapper  
                    listSplitCategoryWrap.add(new CategoryWrapper(prdCategory,  options, false));
                }
            }   
        }else if(typeOfCategoryScreen == constants.SPLIT_SCREEN_TYPE_CHILD) { //If Split clicked from Child pop up window
        	
        	//Increse counter
            screenNum = screenNum+1;
            
            //Temp list of categories to be inserted
            List<RevRecRuleCategory__c> tempListToInserted = new List<RevRecRuleCategory__c>();
            
            //Loop over child popup screen which is now parent for the next level screen
            for(CategoryWrapper cWrp : listSplitCategoryWrap) {
                
                //Checking for null/ if category is not insrted already then first insert and then split that category further
                if(cWrp.category1.Id == null) {
                    cWrp.category1.RevRecRule__c = rule.Id;
                    cWrp.category1.Level__c = screenNum-1;
                    cWrp.category1.RevRecRuleSplitCategory__c = Id.valueOf(categoryParentId);
                    
                    //Add catrgories into list to be inserted before split
                    tempListToInserted.add(cWrp.category1);
                } 
            }
            
            //Checking for list size
            if(tempListToInserted.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_CREATE, 'RevRecRuleCategory__c'))) {
                insert tempListToInserted;
                
                //Query over Product Categories
                for(RevRecRuleCategory__c revCategory : [Select Id, Is_Split__c ,Name, Line_Item__c,
                                                                            Amount__c, Ultimate_Parent__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                            Percent__c, Qty__c, Recognition_Type__c,Sub_Category_support__c,Level__c,
                                                                            RevRecRule__c, RevRecRuleSplitCategory__c, Sequence__c,RevRecRuleSplitCategory__r.Ultimate_Parent__c,
                                                                            (Select Id, Ultimate_Parent__c,Is_Split__c , Name, Line_Item__c,Sub_Category_support__c,
                                                                            Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,
                                                                            Percent__c, Qty__c, Recognition_Type__c,Level__c,
                                                                            RevRecRule__c, RevRecRuleSplitCategory__c, RevRecRuleSplitCategory__r.Ultimate_Parent__c, Sequence__c From RevRecRuleCategorys1__r 
                                                                            ORDER BY Sequence__c) FROM RevRecRuleCategory__c
                                                                            Where RevRecRule__c =: rule.Id ORDER BY CreatedDate ASC]) {
                    
                    //Checking for size of child //Populate map with values
                    if(revCategory.RevRecRuleCategorys1__r.Size() > 0) 
                        mapParentIdWithListOfSplits.put(revCategory.Id, revCategory.RevRecRuleCategorys1__r);
                } 
            }
            //Save splits
            saveSplits();
            
            //Re-initilize list
            listSplitCategoryWrap =  new List<CategoryWrapper>();
            
            //Checking for null
            if(mapParentIdWithListOfSplits != null && mapParentIdWithListOfSplits.containsKey(categoryParentId)) {
            	
            	//fetching relareted split
                List<RevRecRuleCategory__c> productRuleCategories = mapParentIdWithListOfSplits.get(categoryParentId);
                 //Initilize
                listSplitCategoryWrap = new List<CategoryWrapper>();
                
                //Splitted Category     
                RevRecRuleCategory__c splittedCategories = productRuleCategories[Integer.valueOf(categoryToBeSplit) - 1];
                RevRecRuleCategory__c splittedCategories1 = new RevRecRuleCategory__c();
                
                //Assign Split Categories values to new instance
                splittedCategories1.Name = splittedCategories.Name;
                splittedCategories1.Line_Item__c = splittedCategories.Line_Item__c;
                splittedCategories1.Amount__c = splittedCategories.Amount__c;
                splittedCategories1.Category_End_Date__c = splittedCategories.Category_End_Date__c;
                splittedCategories1.Category_Start_Date__c = splittedCategories.Category_Start_Date__c;
                splittedCategories1.Category_Type__c = splittedCategories.Category_Type__c;
                splittedCategories1.Percent__c = splittedCategories.Percent__c;
                splittedCategories1.Qty__c = splittedCategories.Qty__c;
                //splittedCategories1.Recognition_Type__c = splittedCategories.Recognition_Type__c;
                splittedCategories1.RevRecRuleSplitCategory__c = splittedCategories.Id;
                splittedCategories1.RevRecRule__c = rule.Id;
                splittedCategories1.Ultimate_Parent__c = splittedCategories.Ultimate_Parent__c;
                splittedCategories1.Level__c = screenNum -1;
                
                //Line item row which is going to split
                lineItemRow = String.ValueOf(splittedCategories.Sequence__c);
                
                //Query to get the splitted Categories if any categories exist for main Category
                List<RevRecRuleCategory__c> splitCatgs = [Select Id, Is_Split__c ,Name, Line_Item__c, Amount__c, Category_End_Date__c, Category_Start_Date__c, Category_Type__c,Ultimate_Parent__c,
                                                                         Percent__c, Qty__c, Recognition_Type__c,Sub_Category_support__c,
                                                                        RevRecRule__c, RevRecRuleSplitCategory__c,Level__c,
                                                                        Sequence__c,RevRecRuleSplitCategory__r.Name,RevRecRuleSplitCategory__r.Level__c 
                                                                        From RevRecRuleCategory__c 
                                                                        Where RevRecRuleSplitCategory__c =: splittedCategories.Id];
                
                //Checking if no any existig split exist
                if(splitCatgs.size() == 0) {
                    
                    //Initilize value
                    listSplitCategoryWrap = new List<CategoryWrapper>();
                    
                    //Initilize 
                    options.add(new SelectOption('0', '0'));
                    splittedCategories1.sequence__c = 1;
                                
                    //Add values in wrapper list

                    listSplitCategoryWrap.add(new CategoryWrapper(splittedCategories1, options, false));
                }else {
                	
                	 //Loop over existing categories
                    for(RevRecRuleCategory__c prdCategory : splitCatgs) {
                    	   
                        //Initilze value
                        options = new List<SelectOption>();
                        
                        //Loop over category sequence
                        for(Integer j=0 ; j< prdCategory.Sequence__c ; j++)
                            options.add(new SelectOption(String.valueOf(j) , String.valueOf(j)));
                            
                        prdCategory.Level__c = prdCategory.RevRecRuleSplitCategory__r.Level__c + 1;
                         
                        //Populate Category wrapper 
                        listSplitCategoryWrap.add(new CategoryWrapper(prdCategory,  options, false));
                    }
                }
            } 
        }
     }
     
     /**
      *	@description		:	This method is used to save the splits from popup window.
      *
      *	@args				:	-
      * 
      *	@return				:	-
     **/
     public void saveSplits() {
     	
     	//List of categories to be deleted
        List<RevRecRuleCategory__c> catToDelete = new List<RevRecRuleCategory__c>();
        
     	//Set of categories to be deleted
        if(setSplitCategoriesToBeDeleted.size() > 0) {
            
            //Loop over ids
            for(Id catId : setSplitCategoriesToBeDeleted) {
                catToDelete.add(new RevRecRuleCategory__c(Id = catId));
            }
        }
        
        //Checking for list size
        if(catToDelete.size() > 0 && (Utility.checkObjectPermission(Constants.PERMISSION_DELETE, 'RevRecRuleCategory__c')))
            delete catToDelete;
     	
     	//List to be upserted
        List<RevRecRuleCategory__c> listSplitsToBeUpserted = new List<RevRecRuleCategory__c>();
         if(Utility.checkFieldPermission(mapfieldRuleResult,'Is_Split_Categories__c',Constants.PERMISSION_UPSERT))
             rule.Is_Split_Categories__c = true;
         
        //Loop over the split wrapper
        for(CategoryWrapper cSplitWrap : listSplitCategoryWrap) {
        	
        	 //Checking if Product category have actual date NOne
            if(cSplitWrap.category1.Category_End_Date__c != 'NONE' && Utility.checkFieldPermission(mapfieldCatResult,'Recognition_Type__c',Constants.PERMISSION_UPSERT)) 
                cSplitWrap.category1.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_AMORTIZE;
            else 
                cSplitWrap.category1.Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION;
            
            //Checking if rule is not stamped 
            if(cSplitWrap.category1.RevRecRule__c == null)
                cSplitWrap.category1.RevRecRule__c = rule.Id;
           
           //Add split into list to be upserted
           listSplitsToBeUpserted.add(cSplitWrap.category1);
        }
        
        //Add parent category into list to be upserted
        listSplitsToBeUpserted.add(new RevRecRuleCategory__c(Id = listSplitCategoryWrap[0].category1.RevRecRuleSplitCategory__c, Is_Split__c = true));
        
         
        //Checking for the list size 
         if(Utility.checkObjectPermission(Constants.PERMISSION_UPSERT, 'RevRecRuleCategory__c')){
             if(listSplitsToBeUpserted.size() > 0) 
                 upsert listSplitsToBeUpserted;
         }
    }
    
    /**
     *	@
     description	:	This method is used to do some defaults after saving from split screen.
     *
     *	@args			:	-
     *
     *	@return			:	-
    **/
    public void defaults() {
    	
    	//Checking for parent window and set some attribiute 
        if(screenNum == 1 || screenNum == 2 ) {
        	
        	//Populating values after split screen saved
            listCategoryWrap[Integer.valueOf(categoryToBeSplitParent) - 1].category1.Is_Split__c = true;
        }
    }
    
    /**
     *	@description	:	This method is used to add split categories from split popup.
     *
     *	@args			:
     *
     *	@return			:		
    **/
    public void addCategoryForSplit() {
    	
    	//Current sequence
        Integer currentSequence = 0;
        
         //Loop over Category wrapper
        for(CategoryWrapper cWrap : listSplitCategoryWrap) {
            
            //Checking for selected category
            if(cWrap.isSelected) {
                currentSequence = 0;
                currentSequence = Integer.valueOf(cWrap.category1.Sequence__c);
            }   
            
            //Set false to the selected values
            cWrap.isSelected = false;       
        }
        
        //If currenct sequence is 0 then set this to high sequence
        if(currentSequence == 0)
            currentSequence = listSplitCategoryWrap.size();
        
        //Create a new category instance 
        RevRecRuleCategory__c category1 = new RevRecRuleCategory__c(Sequence__c = currentSequence + 1, Name = '', Category_Start_Date__c = 'MANUAL' ,
                                                                                 Category_End_Date__c = 'None', Recognition_Type__c = constants.RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION,
                                                                                 RevRecRuleSplitCategory__c = listSplitCategoryWrap[0].category1.RevRecRuleSplitCategory__c,
                                                                                 Ultimate_Parent__c = listSplitCategoryWrap[0].category1.RevRecRuleSplitCategory__c,
                                                                                 Level__c = listSplitCategoryWrap[0].category1.Level__c);
        
        //Loop over Category wrapper
        for(CategoryWrapper cWrap : listSplitCategoryWrap) {
            
            if(cWrap.category1.Sequence__c > currentSequence) {
                
                //Assign sequence
                if(Utility.checkFieldPermission(mapfieldCatResult,'Sequence__c',Constants.PERMISSION_UPSERT))
                    cWrap.category1.Sequence__c += 1; 
                
                //Initilize list of select option for every wrap instance
                lineItemForBlended = new List<SelectOption>();
                
                //Loop to create the line item options 
                for(Integer i=0 ; i< cWrap.category1.Sequence__c ; i++)
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
        
        listSplitCategoryWrap.add(new CategoryWrapper (category1,  lineItemForBlended, false));
        
        //Map to hold wrapper record with sequence
        Map<Integer, CategoryWrapper> mapSeqWithCatWrap = new   Map<Integer, CategoryWrapper>();
        
        //Loop over List category wrapper
        for(CategoryWrapper cWrap : listSplitCategoryWrap) {
            mapSeqWithCatWrap.put(Integer.valueOf(cWrap.category1.Sequence__c) , cWrap);
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
     *	@description	:	This method is used to remove split categories from split popup.
     *
     *	@args			:
     *
     *	@return			:		
    **/
    public void removeCategoryForSplit() {
    
    	 //Set to hold sequence
        Set<Integer> setSequences = new Set<Integer>();
        Set<String> setString = new Set<String>();
        
        //Map to hold Wrapper with sequence
        Map<Integer, CategoryWrapper> mapSeqWithWrap = new Map<Integer, CategoryWrapper>();
        
        for(CategoryWrapper catWrap : listSplitCategoryWrap) 
            mapSeqWithWrap.put(Integer.valueOf(catWrap.category1.sequence__c), catWrap);
        
        //Loop over wrapper class and checking for the selected record 
        for(CategoryWrapper productCatWrapper : listSplitCategoryWrap) {
            
            //Checking for Selected value
            if(productCatWrapper.isSelected) {
                setSequences.add(Integer.valueOf(productCatWrapper.category1.Sequence__c));
                setString.add(productCatWrapper.category1.Name);
            }
            
            //Set selected value to false
            productCatWrapper.isSelected = false;
        }  
        
        if(setSequences.size() == 0 && setString.size() == 0)   {
        	setSequences.add(Integer.valueOf(listSplitCategoryWrap[listSplitCategoryWrap.size() - 1].category1.Sequence__c));
        	setString.add(listSplitCategoryWrap[listSplitCategoryWrap.size() - 1].category1.Name);
        }    
        //Loop over set and remove selected from the list
        if(setSequences.size() > 0) {
            
            for(Integer seq : setSequences)
                mapSeqWithWrap.remove(Integer.valueOf(seq));
        }
        
        //Initlize category wrap and assign temp list to wrapper
        listSplitCategoryWrap = new List<CategoryWrapper>();
        listSplitCategoryWrap = mapSeqWithWrap.values();
        Integer j = 0;
        
        //Loop over Category wrapper
        for(CategoryWrapper productCatWrapper : listSplitCategoryWrap) {
            productCatWrapper.category1.Sequence__c = j+1; 
            
             //Initilize list of select option for every wrap instance
             lineItemForBlended = new List<SelectOption>();
                
            //Loop to create the line item options 
            for(Integer i=0 ; i< productCatWrapper.category1.Sequence__c ; i++)
                lineItemForBlended.add(new SelectOption(String.valueOf(i) , String.valueOf(i)));
                
             //Assign line item for blended 
             productCatWrapper.lineItemForBlended = lineItemForBlended;
             
            j++;
        }
        
        //If any value selected 
        if(setSequences.size() > 0) {
           
            //Delete Rule category
            for(RevRecRuleCategory__c ruleCatsToDelete : [Select Id From RevRecRuleCategory__c WHERE  Name IN : setString AND RevRecRule__c =: rule.Id])
                setSplitCategoriesToBeDeleted.add(ruleCatsToDelete.Id);
      	}
    }
    
    /**
     *	@description	:	This method is called on change of divide by option.If its prorate then rerender By percentage 
     *
     *	@args			:
     *
     *	@return			:	
    **/
    public void onChangeDivideByOption () { 
    	
    	//Checking for values and set default value
    	if(rule.Divide_By__c != 'prorate' && Utility.checkFieldPermission(mapfieldRuleResult,'Period_or_Exact_Days__c',Constants.PERMISSION_UPSERT)) 
    		rule.Period_or_Exact_Days__c = 'period';
    	else 
    		rule.Period_or_Exact_Days__c = 'exact';
    }
    
    /**
     *	@description	:	This method is called on change of period or exact days options
     *
     *	@args			:
     *
     *	@return			:	
    **/
    public void blankMethodForOnChange() {}
}