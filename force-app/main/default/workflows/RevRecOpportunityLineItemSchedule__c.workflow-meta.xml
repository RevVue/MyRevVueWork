<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FU_Populate_External_OppLineItemId</fullName>
        <field>External_OpportunityLineItemId__c</field>
        <formula>OpportunityLineItemId__c</formula>
        <name>FU_Populate External OppLineItemId</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WF_Populate External Opportunity Line Item</fullName>
        <actions>
            <name>FU_Populate_External_OppLineItemId</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>RevRecOpportunityLineItemSchedule__c.CreatedDate</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
