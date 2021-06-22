codeunit 139178 "CRM Connection String"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CRM Integration]
    end;

    var
        Assert: Codeunit Assert;
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        ConnStringMustInclPasswordErr: Label 'The connection string must include the password placeholder {PASSWORD}.';
        UserNameMustInclDomainErr: Label 'The user name must include the domain when the authentication type is set to Active Directory.';
        UserNameMustBeEmailErr: Label 'The user name must be a valid email address when the authentication type is set to Office 365.';
        IsNotFoundOnThePageErr: Label 'is not found on the page';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t100_AuthTypeDefaultO365ForDynamicsComAddress()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Default "Auth Type" should be "O365" if "Server address" contains '.dynamics.com'
        Initialize;
        // [GIVEN] "Auth Type" =  'AD'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;

        // [WHEN] Validate 'Server Address' as 'http://somedomain.dynamics.com'
        CRMConnectionSetup.Validate("Server Address", 'http://somedomain.dynamics.com');

        // [THEN] "Auth Type" = 'O365'
        CRMConnectionSetup.TestField("Authentication Type", CRMConnectionSetup."Authentication Type"::Office365);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t105_AuthTypeCanBeChangedFromO365ToAD()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Auth Type can be changed to 'AD' if "Server address" contains '.dynamics.com'
        Initialize;
        // [GIVEN] 'Server Address' that contains '.dynamics.com' and "Auth Type" =  'O365'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetup."Server Address" := 'https://somedomain.dynamics.com';

        // [WHEN] Modify "Auth Type" to 'AD'
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::AD);

        // [THEN] "Auth Type" =  'AD'
        CRMConnectionSetup.TestField("Authentication Type", CRMConnectionSetup."Authentication Type"::AD);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t110_AuthTypeDefaultADForNotDynamicsComAddress()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Default "Auth Type" should be "AD" if "Server address" does not contain '.dynamics.com'
        Initialize;
        // [GIVEN] "Auth Type" =  'O365'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;

        // [WHEN] Validate 'Server Address' as 'https://somedomain.com'
        CRMConnectionSetup.Validate("Server Address", 'https://somedomain.com');

        // [THEN] "Auth Type" =  'AD'
        CRMConnectionSetup.TestField("Authentication Type", CRMConnectionSetup."Authentication Type"::AD);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t115_AuthTypeCanBeChangedFromADToO365()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Auth Type can be changed to 'O365' if "Server address" does not contain '.dynamics.com'
        Initialize;
        // [GIVEN] 'Server Address' does not contain '.dynamics.com' and "Auth Type" =  'AD'
        CRMConnectionSetup."Server Address" := 'http://somedomain.com';
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;

        // [WHEN] Modify "Auth Type" to 'O365'
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::Office365);

        // [THEN] "Auth Type" =  'O365'
        CRMConnectionSetup.TestField("Authentication Type", CRMConnectionSetup."Authentication Type"::Office365);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t120_AuthTypeChangeDisablesUserMapping()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UT]
        // [SCENARIO] Changed "Authentication Type" clears "Is User Mapping Required"
        // [GIVEN] "Authentication Type" is 'Office365', "Is User Mapping Required" is Yes
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetup."Is User Mapping Required" := true;
        // [WHEN] Revalidate "Authentication Type" as 'Office365'
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::Office365);
        // [THEN] "Is User Mapping Required" is Yes
        CRMConnectionSetup.TestField("Is User Mapping Required");

        // [WHEN] Change "Authentication Type" to 'AD'
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::AD);
        // [THEN] "Is User Mapping Required" is No
        CRMConnectionSetup.TestField("Is User Mapping Required", false);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t130_AuthTypeControlNotVisibleInSAAS()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [SaaS] [UI]
        Initialize;
        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenView;
        // [THEN] "Authentication Type" is not visible
        asserterror CRMConnectionSetupPage."Authentication Type".Activate;
        Assert.ExpectedError(IsNotFoundOnThePageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t131_AuthTypeControlVisibleInNotSAAS()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UI]
        Initialize;
        // [GIVEN] It is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenView;
        // [THEN] "Authentication Type" is not visible
        Assert.IsTrue(CRMConnectionSetupPage."Authentication Type".Visible, 'Authentication Type is not visible.')
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t135_AuthTypeControlIsEditable()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [UI]
        Initialize;
        // [WHEN] Open CRM Connection Setup Page
        LibraryApplicationArea.DisableApplicationAreaSetup;
        CRMConnectionSetupPage.OpenEdit;
        // [THEN] "Authentication Type" is editable
        Assert.IsTrue(CRMConnectionSetupPage."Authentication Type".Editable, 'Authentication Type is not editable.')
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t150_UserNameMustIncludeDomainForAuthTypeAD()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [User Name]
        // [SCENARIO] "User Name" validation should fail if "Auth Type" is 'AD', but "Domain" is not defined
        Initialize;
        // [GIVEN] "Auth Type" =  'AD'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;
        // [WHEN] Validate "User Name" as 'admin'
        asserterror CRMConnectionSetup.Validate("User Name", 'admin');
        // [THEN] Error: 'User Name must include domain name for authentication type Active Directory'
        Assert.ExpectedError(UserNameMustInclDomainErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t156_UserNameMustIncludeAtSymbolForAuthTypeO365()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Authentication Type] [User Name]
        // [SCENARIO] "User Name" validation should fail if "Auth Type" is 'O365', but "User Name" does not contain '@'
        Initialize;
        // [GIVEN] "Auth Type" =  'O365'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        // [WHEN] Validate "User Name" as 'admin'
        asserterror CRMConnectionSetup.Validate("User Name", 'admin');
        // [THEN] Error: 'User Name must be an e-mail address for authentication type Office 365'
        Assert.ExpectedError(UserNameMustBeEmailErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t200_UserNameWithBackslashFillsDomain()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Domain]
        // [SCENARIO] Validation of "User name" that contains '\' should fill "Domain"
        Initialize;
        // [GIVEN] "Authentication Type" is AD, "Domain" is blank
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;
        CRMConnectionSetup.Domain := '';
        // [WHEN] Validate "User Name" as 'domain001\admin'
        CRMConnectionSetup.Validate("User Name", 'domain001\admin');
        // [THEN] "Domain" is 'domain001'
        CRMConnectionSetup.TestField(Domain, 'domain001');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t205_UserNameWithoutBackslashBlanksDomain()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Domain]
        // [SCENARIO] Validation of "User name" that does not contain '\' should blank "Domain"
        // [GIVEN] "Authentication Type" is O365, "Domain" is 'domain001'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetup.Domain := 'domain001';
        // [WHEN] Validate "User Name" as 'admin'
        CRMConnectionSetup.Validate("User Name", 'admin@domain.com');
        // [THEN] "Domain" is blank
        CRMConnectionSetup.TestField(Domain, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t210_BlankedUserNameKeepDomainUnchanged()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Domain]
        // [SCENARIO] Validation of "User name" as '' should keep "Domain" and "Authentication Type" unchnaged
        // [GIVEN] "Authentication Type" is AD, User Name is "domain001\user", "Domain" is 'domain001'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;
        CRMConnectionSetup."User Name" := 'domain001\user';
        CRMConnectionSetup.Domain := 'domain001';
        // [WHEN] Validate "User Name" as '' (needed for temp connection requiring admin credentials)
        CRMConnectionSetup.Validate("User Name", '');
        // [THEN] "User Name" is '', "Domain" is 'domain001', "Authentication Type" is AD
        CRMConnectionSetup.TestField("Authentication Type", CRMConnectionSetup."Authentication Type"::AD);
        CRMConnectionSetup.TestField("User Name", '');
        CRMConnectionSetup.TestField(Domain, 'domain001');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t220_DomainControlNotVisibleInSAAS()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Domain] [SaaS] [UI]
        Initialize;
        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenView;
        // [THEN] "Domain" is not visible
        asserterror CRMConnectionSetupPage.Domain.Activate;
        Assert.ExpectedError(IsNotFoundOnThePageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t221_DomainControlVisibleInNotSAAS()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Domain] [UI]
        Initialize;
        // [GIVEN] It is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenView;
        // [THEN] "Domain" is visible
        Assert.IsTrue(CRMConnectionSetupPage.Domain.Visible, 'Domain is not visible.')
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t225_DomainControlIsNotEditable()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Domain] [UI]
        Initialize;
        // [WHEN] Open CRM Connection Setup Page
        LibraryApplicationArea.DisableApplicationAreaSetup;
        CRMConnectionSetupPage.OpenEdit;
        // [THEN] "Domain" is not editable
        Assert.IsFalse(CRMConnectionSetupPage.Domain.Editable, 'Domain is editable.')
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t250_ConnectionStringControlNotVisibleInSAAS()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [SaaS] [UI]
        Initialize;
        // [GIVEN] It is SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenView;
        // [THEN] "Connection String" is not visible
        asserterror CRMConnectionSetupPage."Connection String".Activate;
        Assert.ExpectedError(IsNotFoundOnThePageErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t251_ConnectionStringControlVisibleInNotSAAS()
    var
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize;
        // [GIVEN] It is not SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenView;
        // [THEN] "Connection String" is visible
        Assert.IsTrue(CRMConnectionSetupPage."Connection String".Visible, 'Connection String is not visible.')
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t252_ConnectionStringControlNotEditableIfConnectionEnabledO365()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [GIVEN] CRM Connection Setup "Is Enabled" is Yes
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."User Name" := 'user@test.net';
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetup.Insert;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenEdit;
        // [THEN] "Authentication Type" and "Connection String" are not editable
        Assert.IsFalse(CRMConnectionSetupPage."Connection String".Editable, 'Connection String is editable.');
        Assert.IsFalse(CRMConnectionSetupPage."Authentication Type".Editable, 'Authentication Type is editable.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t253_ConnectionStringControlNotEditableIfConnectionEnabledIFD()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [GIVEN] CRM Connection Setup "Is Enabled" is Yes, "Authentication Type" = IFD
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."User Name" := 'user@test.net';
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::IFD;
        CRMConnectionSetup.Insert;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenEdit;
        // [THEN] "Authentication Type" and "Connection String" are not editable
        Assert.IsFalse(CRMConnectionSetupPage."Connection String".Editable, 'Connection String is editable.');
        Assert.IsFalse(CRMConnectionSetupPage."Authentication Type".Editable, 'Authentication Type is editable.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t254_ConnectionStringControEditableIfConnectionDisabledOAuth()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        Initialize;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [GIVEN] CRM Connection Setup "Is Enabled" is No, "Authentication Type" = OAuth
        CRMConnectionSetup."Is Enabled" := false;
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::OAuth;
        CRMConnectionSetup.Insert;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenEdit;
        // [THEN] "Authentication Type" and "Connection String" are not editable
        Assert.IsTrue(CRMConnectionSetupPage."Connection String".Editable, 'Connection String is not editable.');
        Assert.IsTrue(CRMConnectionSetupPage."Authentication Type".Editable, 'Authentication Type is not editable.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t255_ConnectionStringControlNotEditableForO365AndAD()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        // [SCENARIO] "Connection String" control should not be editable if "Auth Type" is 'O365' or 'AD'
        Initialize;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenEdit;
        // [WHEN] "Auth Type" is 'O365'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetupPage."Authentication Type".Value(Format(CRMConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is not editable
        Assert.IsTrue(
          CRMConnectionSetupPage."Connection String".Editable, 'Connection String is not editable for O365.');
        // [WHEN] "Auth Type" is 'AD'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;
        CRMConnectionSetupPage."Authentication Type".Value(Format(CRMConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is not editable
        Assert.IsTrue(
          CRMConnectionSetupPage."Connection String".Editable, 'Connection String is not editable for AD.')
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t256_ConnectionStringControlEditableForOAuthAndIFD()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMConnectionSetupPage: TestPage "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [UI]
        // [SCENARIO] "Connection String" control should be editable if "Auth Type" is 'OAuth' or 'IFD'
        Initialize;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        LibraryApplicationArea.DisableApplicationAreaSetup;
        // [WHEN] Open CRM Connection Setup Page
        CRMConnectionSetupPage.OpenEdit;
        // [WHEN] "Auth Type" is 'OAuth'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::OAuth;
        CRMConnectionSetupPage."Authentication Type".Value(Format(CRMConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is editable
        Assert.IsTrue(
          CRMConnectionSetupPage."Connection String".Editable, 'Connection String is not editable for OAuth.');
        // [WHEN] "Auth Type" is 'IFD'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::IFD;
        CRMConnectionSetupPage."Authentication Type".Value(Format(CRMConnectionSetup."Authentication Type"));
        // [THEN] "Connection String" is editable
        Assert.IsTrue(
          CRMConnectionSetupPage."Connection String".Editable, 'Connection String is not editable for IFD.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t257_BlankConnectionStringIsCalculatedOnConnect()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String] [UT]
        // [SCENARIO] Blank "Connection String" is getting filled on attempt to connect
        // [GIVEN] Connection is set, but "Connection String" is blank
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);
        CRMConnectionSetup.Get;
        Clear(CRMConnectionSetup."Server Connection String");
        CRMConnectionSetup.Modify;
        // [WHEN] Connect
        CRMConnectionSetup.UnregisterConnection;
        CRMConnectionSetup.RegisterConnection;
        // [THEN] "Connection String" is filled in the variable
        ConnectionString := CRMConnectionSetup.GetConnectionString;
        Assert.ExpectedMessage('AuthType=Office365;', ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
        // [THEN] "Connection String" is saved to the record
        CRMConnectionSetup.Get;
        Assert.ExpectedMessage(ConnectionString, CRMConnectionSetup.GetConnectionString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t258_BlankConnectionStringIsCalculatedNotSavedOnTempConnect()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String] [UT]
        // [SCENARIO] Blank "Connection String" is getting filled on attempt to connect on the temp rec
        // [GIVEN] Temp Connection is set, but "Connection String" is blank
        LibraryCRMIntegration.CreateCRMConnectionSetup('', '@@test@@', true);
        CRMConnectionSetup.Get;
        Clear(CRMConnectionSetup."Server Connection String");
        CRMConnectionSetup.Delete;
        // [WHEN] Connect
        CRMConnectionSetup.UnregisterConnection;
        CRMConnectionSetup.RegisterConnection;
        // [THEN] "Connection String" is filled
        ConnectionString := CRMConnectionSetup.GetConnectionString;
        Assert.ExpectedMessage('AuthType=Office365;', ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t260_DefaultConnectionStringIncludesPwdPlaceholder()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [Password]
        // [SCENARIO] Default "Connection String" shows '{PASSWORD}' as a placeholder for real password
        // [GIVEN] "Auth Type" is 'O365'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        // [WHEN] "User Name" is validated
        CRMConnectionSetup.Validate("User Name", 'admin@domain.com');
        // [THEN] "Connection String" generated and contains '{PASSWORD}'
        Assert.ExpectedMessage('{PASSWORD}', CRMConnectionSetup.GetConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t261_ModifiedConnectionStringMustIncludePwdPlaceholder()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        // [FEATURE] [Connection String] [Password]
        // [SCENARIO] Modified "Connection String" must contain '{PASSWORD}' placeholder
        // [GIVEN] "Auth Type" is 'O365' and "Connection String" contains '<PASSWORD>'
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::Office365;
        CRMConnectionSetup.Validate("User Name", 'admin@domain.com');
        // [WHEN] Modified "Connection String" does not contain '<PASSWORD>'
        asserterror CRMConnectionSetup.SetConnectionString('modified line without the placeholder');
        // [THEN] Error: "Connection String must contain {PASSWORD} as password placeholder."
        Assert.ExpectedError(ConnStringMustInclPasswordErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t270_ConnectionStringForO365MatchesTemplate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'O365' should match the O365 string template
        Initialize;
        // [GIVEN] "Server Address" is set, "Auth Type" is 'O365'
        CRMConnectionSetup.Validate("Server Address", 'https://somedomain.com');
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::Office365);
        // [WHEN] Validate "User Name"
        CRMConnectionSetup.Validate("User Name", 'admin@somedomain.com');

        // [THEN] "Connection String" contains parameters: AuthType=O365, Url, Username, Password.
        ConnectionString := CRMConnectionSetup.GetConnectionString;
        Assert.ExpectedMessage('AuthType=Office365', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CRMConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'UserName=' + CRMConnectionSetup."User Name", ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
        // [THEN] "Connection String" does not contain parameter: Domain.
        asserterror Assert.ExpectedMessage('Domain=', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t271_ConnectionStringForADMatchesTemplate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'AD' should match the AD string template
        Initialize;
        // [GIVEN] "Server Address" is set, "Auth Type" is 'AD'
        CRMConnectionSetup.Validate("Server Address", 'http://somedomain.com');
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::AD);
        // [WHEN] Validate "User Name"
        CRMConnectionSetup.Validate("User Name", 'somedomain\admin');

        // [THEN] "Connection String" contains parameters: AuthType=O365, Url, Domain, Username, Password.
        ConnectionString := CRMConnectionSetup.GetConnectionString;
        Assert.ExpectedMessage('AuthType=AD', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CRMConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'Domain=' + CRMConnectionSetup.Domain, ConnectionString);
        Assert.ExpectedMessage('UserName=admin', ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t272_ConnectionStringForOAuthMatchesTemplate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'OAuth' should match the OAuth string template
        Initialize;
        // [GIVEN] "Server Address" is set, "Auth Type" is 'OAuth'
        CRMConnectionSetup.Validate("Server Address", 'http://somedomain.com');
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::OAuth);
        // [WHEN] Validate "User Name"
        CRMConnectionSetup.Validate("User Name", 'admin@somedomain.com');

        // [THEN] "Connection String" contains parameters: AuthType=OAuth, Url, Domain, Username, Password.
        ConnectionString := CRMConnectionSetup.GetConnectionString;
        Assert.ExpectedMessage('AuthType=OAuth', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CRMConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'UserName=' + CRMConnectionSetup."User Name", ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
        // [THEN] "Connection String" contains parameters: AppId, RedirectUri, TokenCacheStorePath, LoginPrompt.
        Assert.ExpectedMessage('AppId= ;', ConnectionString);
        Assert.ExpectedMessage('RedirectUri= ;', ConnectionString);
        Assert.ExpectedMessage('TokenCacheStorePath= ;', ConnectionString);
        Assert.ExpectedMessage('LoginPrompt=Auto', ConnectionString);
        // [THEN] "Connection String" does not contain parameter: Domain.
        asserterror Assert.ExpectedMessage('Domain=', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t273_ConnectionStringForIFDMatchesTemplate()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionString: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO] Default "Connection String" for 'IFD' should match the AD string template
        Initialize;
        // [GIVEN] "Server Address" is set, "Auth Type" is 'IFD'
        CRMConnectionSetup.Validate("Server Address", 'http://somedomain.com');
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::IFD);
        // [WHEN] Validate "User Name"
        CRMConnectionSetup.Validate("User Name", 'somedomain\admin');

        // [THEN] "Connection String" contains parameters: AuthType=O365, Url, Domain, Username, Password.
        ConnectionString := CRMConnectionSetup.GetConnectionString;
        Assert.ExpectedMessage('AuthType=IFD', ConnectionString);
        Assert.ExpectedMessage(
          'Url=' + CRMConnectionSetup."Server Address", ConnectionString);
        Assert.ExpectedMessage(
          'Domain=' + CRMConnectionSetup.Domain, ConnectionString);
        Assert.ExpectedMessage('UserName=admin', ConnectionString);
        Assert.ExpectedMessage('Password={PASSWORD}', ConnectionString);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t280_UserO365MappedIfAuthEmailAndInternalEmailMatch()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSystemuser: Record "CRM Systemuser";
        User: Record User;
    begin
        // [FEATURE] [User Mapping]
        // [SCENARIO] User mapping should be set for Auth Type 'O365' if NAV User's "O365 auth. email" matches CRM User's "InternalEmail"
        Initialize;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;

        // [GIVEN] "Auth Type" is 'O365'
        CRMConnectionSetup.Get;
        CRMConnectionSetup."User Name" := 'sync@domain.com';
        CRMConnectionSetup.Validate("Authentication Type", CRMConnectionSetup."Authentication Type"::Office365);

        // [GIVEN] NAV User, where "User Name" is 'Domain\user10', "O365 auth. email" is 'user10@domain.com'
        CreateUser(User, 'user10@domain.com');
        // [GIVEN] CRM system user, where User name is 'domain\user1', Email is 'user10@domain.com'
        CreateCRMUser(CRMSystemuser, 'domain\user1', 'user10@domain.com');

        // [WHEN] Turn on "Is User Mapping Required" on CRM Connection Setup page
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Is User Mapping Required" := true;
        Assert.IsTrue(CRMConnectionSetup.IsCurrentUserMappedToCrmSystemUser, 'User is not mapped.');
        // [THEN] "Current User is Mapped" is Yes
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure t281_UserADMappedIfUserNameAndDomainNameMatch()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSystemuser: Record "CRM Systemuser";
        User: Record User;
    begin
        // [FEATURE] [User Mapping]
        // [SCENARIO] User mapping should be set for Auth Type 'AD' if NAV User's "User Name" matches CRM User's "DomainName"
        Initialize;
        LibraryCRMIntegration.ResetEnvironment;
        LibraryCRMIntegration.ConfigureCRM;

        // [GIVEN] NAV User, where "User Name" is 'domain\user1', "O365 auth. email" is ''
        CreateUser(User, '');
        // [GIVEN] CRM system user, where User name is 'domain\user1', Primary Email is 'admin@domain.com'
        CreateCRMUser(CRMSystemuser, User."User Name", 'admin@domain.com');

        // [GIVEN] "Auth Type" is 'AD'
        CRMConnectionSetup.Get;
        CRMConnectionSetup."User Name" := 'domain\sync';
        CRMConnectionSetup."Authentication Type" := CRMConnectionSetup."Authentication Type"::AD;

        // [WHEN] Turn on "Is User Mapping Required" on CRM Connection Setup page
        CRMConnectionSetup."Is Enabled" := true;
        CRMConnectionSetup."Is User Mapping Required" := true;
        Assert.IsTrue(CRMConnectionSetup.IsCurrentUserMappedToCrmSystemUser, 'User is not mapped.');
        // [THEN] "Current User is Mapped" is Yes
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t300_CRMConnectionStringHandleLargeText()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionStringValue: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO 229446] Connection String can handle text > 250 symbols
        Initialize;

        // [WHEN] Text of length > 250 symbols assigned to CRM Connection String
        ConnectionStringValue := LibraryUtility.GenerateRandomText(300) + '{PASSWORD}';
        CRMConnectionSetup.SetConnectionString(ConnectionStringValue);

        // [THEN] The text value is saved to CRM Connection Setup record
        Assert.ExpectedMessage(ConnectionStringValue, CRMConnectionSetup.GetConnectionString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure t301_CRMConnectionCanBeEmpty()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionStringValue: Text;
    begin
        // [FEATURE] [Connection String]
        // [SCENARIO 234959] Connection String can be empty
        Initialize;

        // [GIVEN] Connection String is filled
        ConnectionStringValue := LibraryUtility.GenerateRandomText(100) + '{PASSWORD}';
        CRMConnectionSetup.SetConnectionString(ConnectionStringValue);
        CRMConnectionSetup.Insert;
        Assert.ExpectedMessage(ConnectionStringValue, CRMConnectionSetup.GetConnectionString);

        // [WHEN] Connection string is updated with empty value
        ConnectionStringValue := '';
        CRMConnectionSetup.SetConnectionString(ConnectionStringValue);
        CRMConnectionSetup.Find;
        // [THEN] No error appear and the value is saved
        Assert.AreEqual('', CRMConnectionSetup.GetConnectionString, 'Wrong connection string value');
    end;

    local procedure Initialize()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        CRMConnectionSetup.DeleteAll;
        LibraryApplicationArea.EnableFoundationSetup;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateCRMUser(var CRMSystemuser: Record "CRM Systemuser"; DomainUserName: Text[250]; IntEmail: Text[100])
    begin
        LibraryCRMIntegration.CreateCRMSystemUser(CRMSystemuser);
        CRMSystemuser.DomainName := DomainUserName;
        CRMSystemuser.Validate(InternalEMailAddress, IntEmail);
        CRMSystemuser.Modify;
    end;

    local procedure CreateUser(var User: Record User; AuthEmail: Text[250])
    begin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");
        User.SetRange("Windows Security ID", Sid);
        User.FindFirst;
        User.Validate("Authentication Email", AuthEmail);
        User.Modify;
    end;
}
