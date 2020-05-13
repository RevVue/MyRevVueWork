//This Class is used for the generic lookup reference 
public with sharing class LookUpCompomentController {
    
    //Properties
    public SObject inputObject { get; set; }
    public String fieldName { get; set; }

    
    //Getter lookup boolean value
    public Boolean isLookup {
        get {
            DisplayType dispType = getFieldDescribe().getType();
            if (dispType == Schema.DisplayType.reference)
                return true;
            else
                return false;
        }
    }

    //Getter for SField
    public SObjectField getSField() { 
        if (inputObject != null && fieldName != null) 
            return inputObject.getSObjectType().getDescribe().fields.getMap().get(fieldName);
        else
            return null;
    }
    
    //Getter for FieldDescribe
    public DescribeFieldResult getFieldDescribe() { 
        SObjectField sf = getSField();
        if (sf != null) {
            return sf.getDescribe();
            }
        else
            return null;
    }

    //Getter for objectName 
    public String objectName { 
        get {
        if (inputObject != null)
            return inputObject.getSObjectType().getDescribe().getName();
        else
            return '';
        }
    }   


}