/**
 *  Description     :   Class to hold the constant values.
 *
 *  Created By      :   
 *
 *  Created Date    :   10/31/2014
 *
 *  Version         :   V1.0
 *
 *  Revision Log    :   10/31/2014 - Created  
 *
**/
public with sharing class Constants {
	 
    //Constant for OverriddenRuleInsertionOnOpptyLevel
    public final static String START_END_DATE_ERROR_MESSAGE = 'Start Date and end Date should not be null for Rule and End Date must be greater than start date';
   	public final static String END_DATE_CANNOT_GREATER_ERROR_MESSAGE = 'For Amortize Milestone Rule end Date must be greater than start date';
    public final static String START_END_DATE_CANNOT_NUll_ERROR_MESSAGE = 'Revenue allocation/distribution cannot be calculated because some revenue dates (Start, End, etc.) are missing for the following:';
    public final static String START_RULE_CANNOT_NUll_ERROR_MESSAGE = 'The revenue for cannot be fully calculated. There following products in the opportunity do not have a rule assigned. Please correct:';
    
    public final static String NO_RULE = 'No Rule is assigned to the product, and no default rule defined for';
    
	//Constanst to hold the recognition type values
	public final static String RULE_RECOGNITION_TYPE_AMORTIZE_MILESTONE = 'Amortized Milestone';
	public final static String RULE_RECOGNITION_TYPE_MILESTONE = 'Milestone';
	public final static String PRODUCT_RULE_AMORTIZED_BY_AMOUNT = 'amount';
	public final static String PRODUCT_RULE_AMORTIZED_BY_QUANTITY = 'qty';
	public static Boolean IS_BY_PASS_TRIGGER = false;
	public static Boolean IS_BY_PASS_RULE_TRIGGER = false;
	public static Boolean IS_BY_PASS_LINE_ITEM_TRIGGER = false;
	public static Boolean IS_BY_PASS_OPP_TRIGGER = false;
	public static Boolean IS_BY_PASS_SCHEDULES_TRIGGER = false;
	public final static String MILESTONE_DATE_MANUAL = 'MANUAL';
	public final static String PACKAGE_PREFIX = 'AppRopozSLN__';
	public final static String SOBJECT_OPPORTUNITY_COLON = 'OPPORTUNITY:';
	public final static String SOBJECT_LINE_ITEM_COLON = 'PRODUCT:';
    public final static String SOBJECT_CONTRACT_COLON = 'CONTRACT:';
	public final static String SOBJECT_OPPORTUNITY = 'OPPORTUNITY';
	public final static String SOBJECT_LINE_ITEM = 'OpportunityLineItem';
    public final static String currentPackagePrefix = 'AppRopozSLN';
    
    //Constants to hold the type of the dml statements.
	public static final String PERMISSION_UPDATE = 'Update';
    public static final String PERMISSION_UPSERT = 'Upsert';
	public static final String MAP_CONTAINS = 'Contains';
	public static final String PERMISSION_CREATE = 'Create';
	public static final String PERMISSION_ACCESS = 'Access';
	public static final String PERMISSION_QUERYABLE = 'Queryable';
	public static final String PERMISSION_DELETE = 'Delete';
    
	//Variables added for Blended revenue
	public final static String RULE_RECOGNITION_TYPE_BLENDED_REVENUE = 'Blended Revenue';
	public final static String RULE_RECOGNITION_TYPE_SINGLE_TRANSACTION = 'Single Transaction';
	public final static String RULE_RECOGNITION_TYPE_AMORTIZE = 'Amortize';
	public final static String RULE_CATEGORY_TYPE_PERCENT = 'Percent';
	public final static String RULE_CATEGORY_TYPE_AMOUNT = 'Amount';
	public final static String RULE_CATEGORY_TYPE_QTY = 'Qty';

	//Variable added for Blended split functionality
	public final static String SPLIT_SCREEN_TYPE_CHILD = 'Child';
	public final static String SPLIT_SCREEN_TYPE_PARENT = 'Parent';	
	
	//Variable to checki if it is updating from product rule page
	public static Boolean IS_UPDATING_FROM_PRODUCTRULE_PAGE = false;
	
	//Varoable to hold if line item total price changes 
	public static Boolean IS_LINE_ITEM_TOTAL_PRICE_CHANGE = false;
	
	//Variable to hold if line item total price changes 
	public static Boolean IS_LINE_ITEM_TOTAL_PRICE_CHANGE_FROM_ADJUST = false;
	 
	//Variables to use in Rule Assignment functionality
	public final static List<SelectOption> TEXT_FILTER_OPERATORS = new List<SelectOption>();
	
	//Variable for Batch_EvaluateRevRecSchedule
	public static Boolean ISBATCHCOMPLITED = true;

	//Constant for OpportunityLineItemTriggerHelper
    public static final Set<String> ASYNC_APEX_JOB_PENDING_STATUSES = new Set<String>{'Pending', 'Queue'};     
	
	public static List<SelectOption> getFilterOperatorOptions() {
		
		TEXT_FILTER_OPERATORS.add(new SelectOption('None' , 'None'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('IN' , 'Equals to'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('NOT IN' , 'Not equals to'));
		/** TEXT_FILTER_OPERATORS.add(new SelectOption('startsWith' , 'startsWith'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('contains' , 'contains'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('endsWith' , 'endsWith'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('doesNotContains' , 'does not contains'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('includes' , 'includes'));
		TEXT_FILTER_OPERATORS.add(new SelectOption('excludes' , 'excludes')); **/ 
		
		return TEXT_FILTER_OPERATORS;
	}
	
	//Variables to use in Rule Assignment functionality
	public final static List<SelectOption> TEXT_FILTER_CONDITIONS = new List<SelectOption>();
	
	public static List<SelectOption> getFilterConditionOptions() {
		
		TEXT_FILTER_CONDITIONS.add(new SelectOption('None' , 'None'));
		TEXT_FILTER_CONDITIONS.add(new SelectOption('Name' , 'Opportunity Name'));
		TEXT_FILTER_CONDITIONS.add(new SelectOption('Family' , 'Product Family'));
		TEXT_FILTER_CONDITIONS.add(new SelectOption('Product Name' , 'Product Name'));
		
		return TEXT_FILTER_CONDITIONS;
	}
	
	//Variables
	public final static String OPERATOR_IN = 'IN';
	public final static String OPERATOR_NOT_IN = 'NOT IN';
	public final static String FIELD_NAME_OPPORTUNITY_NAME = 'Name';
	public final static String FIELD_NAME_PRODUCT_NAME = 'Product Name';
	public final static String FIELD_NAME_FAMILY_NAME = 'Family';	
	
	//Var for AM 
	public static Boolean IS_CHANGED_RULE = false;
	public static Boolean IS_BLANK_PRIOR_VAL = false;
	
	//Variable to show Page message while records are more than 1000 on page
	public final static String MORE_THAN_1000_RECORDS = 'There are more than 1000 records in database,so we are showing first 1000 only. Use search text to narrow down the criteria.';
	
	//Error messages
	public final static String ERROR_MESSAGE_BASED_ON_DATES = 'Please revise your opportunity/product dates for Revenue Recognition. Some seem to be happening prior to the Opportunity Close Date';
	
	//Error message while Amortize total amount is greater than Opportunity total amount
	public final static String WARNING_MESSAGE_ACTUAL_AMOUNT_IS_GREATER_THAN_ACTUAL = 'The modification to the amortize milestones'+
        											' revenue values for “Sales-Projected Forecast” and/or “Actual Values" cannot be'+
        											' saved - the total SUM of the is higher than the Line Item Amount. Please, either'+
        											' adjust your "Sales-Projected Forecast” and/or “Actual Amount” values or adjust the'+
        											' revenue using the “Adjust Future Revenue” or the "Adjust Product Pricing/Opportunity'+
        											' Amount” buttons (the latter will increase your overall opportunity amount)';
	
    //Error message while Amortize total amount is less than Opportunity total amount
    public final static String WARNING_MESSAGE_ACTUAL_AMOUNT_IS_LESS_THAN_ACTUAL = 'The total SUM of the amount is less than the Line Item Amount. '+
        											'If you want to adjust the amount, then please either adjust your “Actual Amount” values or adjust the'+
        											' revenue using the “Adjust Future Revenue” or the "Adjust Product Pricing/Opportunity'+
        											' Amount” buttons (the latter will increase your overall opportunity amount). '+
        											'If not, then you can hit save button again';
    
	//Error message while Amortize total amount is greater than Opportunity manual amount
	public final static String WARNING_MESSAGE_SALE_AMOUNT_IS_GREATER_THAN_ACTUAL = 'The modification to the amortize milestones revenue Sales Forecast Values cannot be'
																				    +' saved - the total SUM of the Sales Forecast amounts is higher than the Line Item Amount.'
																				    +' Please, either adjust your Sales Forecast amounts values or Adjust Product '
																				    + 'Pricing/Opportunity Amount (which will increase your overall opportunity amount)';
	
	
	//Error messag while Milestone total amount is greatee than opp total amount
	public final static String WARNING_MESSAGE_AMOUNT_IS_GREATER_THAN_OPP = 'The modification to the milestones revenue cannot be saved - the total SUM of Milestone Amounts'
																			+' is higher than the Line Item Amount. Please, either adjust your milestones amount values or'
																			+' Adjust Product Pricing/Opportunity Amount (which will increase your overall opportunity amount)';
	
	//Error message while Amortize total amount is greater than Opportunity total amount
	public final static String WARNING_MESSAGE_MANUAL_AMOUNT_IS_GREATER_THAN_ACTUAL = 'The Manual Forecast exceeds the line item total amount. Please correct';
	
	//Over start and end date
	public final static String START_END_DATE_RANGE_EXCEED = 'Please verify your Start Date/End Date range. It seems to big and REVview cannot calculate this opportunity as it could violate' 
															+ ' salesforce limit of 10,000 records';
	
	public final static String RULE_ALREADY_EXIST = 'There is already a rule with the same name. Please select a different name for the rule.';
	public final static String RULE_START_AND_END_PERCENTAGE_NOT_MORE_THAN_100 = 'The Amortization Start Percentage and End Percentage do not  add to 100%. Please adjust';
	
	//Private String to hold Month Name Corresponding to month number
	private static Map<Integer, String > monthsMap = new Map<Integer, String> {
	  1 => 'January' ,
	  2 => 'February',
	  3 => 'March',
	  4 => 'April',
	  5 => 'May',
	  6 => 'June',
	  7 => 'July',
	  8 => 'August',
	  9 => 'September',
	  10 => 'October',
	  11 => 'November',
	  12 => 'December'
	};

	//Method to return the month name  corresponding to number
	public static String convertNumberToMonthText(Integer monthNumber) {
	 
	  return monthsMap.get(monthNumber);
	}
}