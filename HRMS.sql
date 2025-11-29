USE master;
GO

IF EXISTS (SELECT name
           FROM sys.databases
           WHERE name = 'HRMS')
    BEGIN
        ALTER DATABASE HRMS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        DROP DATABASE HRMS;
    END
GO

CREATE DATABASE HRMS;
GO


USE HRMS;
GO

CREATE TABLE Position
(
    position_id      INT PRIMARY KEY IDENTITY (1, 1),
    position_title   VARCHAR(100) NOT NULL,
    responsibilities varchar(max),
    STATUS           VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE PayGrade
(
    pay_grade_id INT PRIMARY KEY IDENTITY (1, 1),
    grade_name   VARCHAR(50)    NOT NULL,
    min_salary   DECIMAL(10, 2) NOT NULL,
    max_salary   DECIMAL(10, 2) NOT NULL
);

CREATE TABLE TaxForm
(
    tax_form_id     INT PRIMARY KEY IDENTITY (1, 1),
    jurisdiction    VARCHAR(100) NOT NULL,
    validity_period VARCHAR(100) NOT NULL,
    form_content    varchar(max) NOT NULL
);

CREATE TABLE Department
(
    department_id      INT PRIMARY KEY IDENTITY (1, 1),
    department_name    VARCHAR(100) NOT NULL,
    purpose            varchar(max),
    department_head_id INT          NULL
);

CREATE TABLE Currency
(
    CurrencyCode VARCHAR(10) PRIMARY KEY,
    CurrencyName VARCHAR(50)    NOT NULL UNIQUE,
    ExchangeRate DECIMAL(10, 4) NOT NULL,
    CreatedDate  DATETIME DEFAULT GETDATE(),
    LastUpdated  DATETIME DEFAULT GETDATE()
);

CREATE TABLE SalaryType
(
    salary_type_id    INT PRIMARY KEY IDENTITY (1, 1),
    TYPE              VARCHAR(50) NOT NULL,
    payment_frequency VARCHAR(50) NOT NULL,
    currency          VARCHAR(50) NOT NULL,
    FOREIGN KEY (currency) REFERENCES Currency (CurrencyName)
);

CREATE TABLE Insurance
(
    insurance_id      INT PRIMARY KEY IDENTITY (1, 1),
    TYPE              VARCHAR(50)   NOT NULL,
    contribution_rate DECIMAL(5, 2) NOT NULL,
    coverage          varchar(max)  NOT NULL
);

CREATE TABLE Contract
(
    contract_id   INT PRIMARY KEY IDENTITY (1, 1),
    TYPE          VARCHAR(50) NOT NULL,
    start_date    DATE        NOT NULL,
    end_date      DATE        NULL,
    current_state VARCHAR(50) NOT NULL
);

CREATE TABLE Employee
(
    employee_id             INT PRIMARY KEY IDENTITY (1, 1),
    first_name              VARCHAR(50)         NOT NULL,
    last_name               VARCHAR(50)         NOT NULL,
    full_name               VARCHAR(200),
    national_id             VARCHAR(50) UNIQUE,
    date_of_birth           DATE,
    country_of_birth        VARCHAR(50),
    phone                   VARCHAR(20),
    email                   VARCHAR(100) UNIQUE NOT NULL,
    address                 VARCHAR(150),
    emergency_contact_name  VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    relationship            VARCHAR(50),
    biography               varchar(max),
    profile_image           VARCHAR(255),
    employment_progress     VARCHAR(50),
    account_status          VARCHAR(20) DEFAULT 'Active',
    employment_status       VARCHAR(50),
    hire_date               DATE                NOT NULL,
    is_active               BIT         DEFAULT 1,
    profile_completion      INT         DEFAULT 0,
    department_id           INT,
    position_id             INT,
    manager_id              INT                 NULL,
    contract_id             INT,
    tax_form_id             INT,
    salary_type_id          INT,
    pay_grade               INT,
    FOREIGN KEY (position_id) REFERENCES Position (position_id),
    FOREIGN KEY (pay_grade) REFERENCES PayGrade (pay_grade_id),
    FOREIGN KEY (tax_form_id) REFERENCES TaxForm (tax_form_id),
    FOREIGN KEY (department_id) REFERENCES Department (department_id),
    FOREIGN KEY (manager_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (salary_type_id) REFERENCES SalaryType (salary_type_id),
    FOREIGN KEY (contract_id) REFERENCES Contract (contract_id)
);

ALTER TABLE
    Department
    ADD
        FOREIGN KEY (department_head_id) REFERENCES Employee (employee_id);

CREATE TABLE HRAdministrator
(
    employee_id                INT PRIMARY KEY,
    approval_level             VARCHAR(50)  NOT NULL,
    record_access_scope        varchar(max) NOT NULL,
    document_validation_rights varchar(max) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE SystemAdministrator
(
    employee_id            INT PRIMARY KEY,
    system_privilege_level VARCHAR(50)  NOT NULL,
    configurable_fields    varchar(max) NOT NULL,
    audit_visibility_scope varchar(max) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE PayrollSpecialist
(
    employee_id           INT PRIMARY KEY,
    assigned_region       VARCHAR(50) NOT NULL,
    processing_frequency  VARCHAR(50) NOT NULL,
    last_processed_period VARCHAR(50),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE LineManager
(
    employee_id            INT PRIMARY KEY,
    team_size              INT NOT NULL,
    supervised_departments VARCHAR(255),
    approval_limit         VARCHAR(50),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE Skill
(
    skill_id    INT PRIMARY KEY IDENTITY (1, 1),
    skill_name  VARCHAR(100) NOT NULL,
    description varchar(max)
);

CREATE TABLE Employee_Skill
(
    employee_id       INT NOT NULL,
    skill_id          INT NOT NULL,
    proficiency_level VARCHAR(50),
    PRIMARY KEY (employee_id, skill_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (skill_id) REFERENCES Skill (skill_id)
);

CREATE TABLE Verification
(
    verification_id   INT PRIMARY KEY IDENTITY (1, 1),
    verification_type VARCHAR(50)  NOT NULL,
    issuer            VARCHAR(100) NOT NULL,
    issue_date        DATE         NOT NULL,
    expiry_period     DATE
);

CREATE TABLE Employee_Verification
(
    employee_id     INT NOT NULL,
    verification_id INT NOT NULL,
    PRIMARY KEY (employee_id, verification_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (verification_id) REFERENCES Verification (verification_id)
);

CREATE TABLE Role
(
    role_id   INT PRIMARY KEY IDENTITY (1, 1),
    role_name VARCHAR(100) NOT NULL,
    purpose   varchar(max)
);

CREATE TABLE Employee_Role
(
    employee_id   INT NOT NULL,
    role_id       INT NOT NULL,
    assigned_date DATE DEFAULT GETDATE(),
    PRIMARY KEY (employee_id, role_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (role_id) REFERENCES Role (role_id)
);

CREATE TABLE RolePermission
(
    role_id         INT          NOT NULL,
    permission_name VARCHAR(100) NOT NULL,
    allowed_action  VARCHAR(100),
    PRIMARY KEY (role_id, permission_name),
    FOREIGN KEY (role_id) REFERENCES Role (role_id)
);

CREATE TABLE FullTimeContract
(
    contract_id           INT PRIMARY KEY,
    leave_entitlement     INT NOT NULL,
    insurance_eligibility VARCHAR(100),
    weekly_working_hours  INT NOT NULL,
    FOREIGN KEY (contract_id) REFERENCES Contract (contract_id)
);

CREATE TABLE PartTimeContract
(
    contract_id   INT PRIMARY KEY,
    working_hours INT            NOT NULL,
    hourly_rate   DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (contract_id) REFERENCES Contract (contract_id)
);

CREATE TABLE ConsultantContract
(
    contract_id      INT PRIMARY KEY,
    project_scope    varchar(max)   NOT NULL,
    fees             DECIMAL(10, 2) NOT NULL,
    payment_schedule VARCHAR(100),
    FOREIGN KEY (contract_id) REFERENCES Contract (contract_id)
);

CREATE TABLE InternshipContract
(
    contract_id     INT PRIMARY KEY,
    mentoring       VARCHAR(100),
    evaluation      varchar(max),
    stipend_related DECIMAL(10, 2),
    FOREIGN KEY (contract_id) REFERENCES Contract (contract_id)
);

CREATE TABLE Termination
(
    termination_id INT PRIMARY KEY IDENTITY (1, 1),
    date           DATE         NOT NULL,
    reason         varchar(max) NOT NULL,
    contract_id    INT          NOT NULL,
    FOREIGN KEY (contract_id) REFERENCES Contract (contract_id)
);

CREATE TABLE Reimbursement
(
    reimbursement_id INT PRIMARY KEY IDENTITY (1, 1),
    TYPE             VARCHAR(50) NOT NULL,
    claim_type       VARCHAR(50) NOT NULL,
    approval_date    DATE,
    current_status   VARCHAR(50) NOT NULL,
    employee_id      INT         NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE Mission
(
    mission_id  INT PRIMARY KEY IDENTITY (1, 1),
    destination VARCHAR(50) NOT NULL,
    start_date  DATE        NOT NULL,
    end_date    DATE        NOT NULL,
    STATUS      VARCHAR(50) NOT NULL,
    employee_id INT         NOT NULL,
    manager_id  INT         NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (manager_id) REFERENCES Employee (employee_id)
);

CREATE TABLE  Leave
(
    leave_id          INT PRIMARY KEY IDENTITY (1, 1),
    leave_type        VARCHAR(50) NOT NULL,
    leave_description varchar(max)
);

CREATE TABLE VacationLeave
(
    leave_id          INT PRIMARY KEY,
    carry_over_days   INT,
    approving_manager VARCHAR(100),
    FOREIGN KEY (leave_id) REFERENCES Leave (leave_id)
);

CREATE TABLE SickLeave
(
    leave_id              INT PRIMARY KEY,
    medical_cert_required BIT,
    physician_id          VARCHAR(50),
    FOREIGN KEY (leave_id) REFERENCES Leave (leave_id)
);

CREATE TABLE ProbationLeave
(
    leave_id               INT PRIMARY KEY,
    eligibility_start_date DATE,
    probation_period       INT,
    FOREIGN KEY (leave_id) REFERENCES Leave (leave_id)
);

CREATE TABLE HolidayLeave
(
    leave_id             INT PRIMARY KEY,
    holiday_name         VARCHAR(100),
    official_recognition BIT,
    regional_scope       VARCHAR(100),
    FOREIGN KEY (leave_id) REFERENCES Leave (leave_id)
);

CREATE TABLE LeavePolicy
(
    policy_id          INT PRIMARY KEY IDENTITY (1, 1),
    name               VARCHAR(100) NOT NULL,
    purpose            varchar(max),
    eligibility_rules  varchar(max),
    notice_period      INT,
    special_leave_type VARCHAR(50),
    reset_on_new_year  BIT DEFAULT 0,
    leave_type_id      INT,
max_duration INT,
    workflow_type VARCHAR(50),   
    FOREIGN KEY (leave_type_id) REFERENCES Leave (leave_id)
);

CREATE TABLE LeaveRequest
(
    request_id      INT PRIMARY KEY IDENTITY (1, 1),
    employee_id     INT         NOT NULL,
    leave_id        INT         NOT NULL,
    justification   varchar(max),
    duration        INT         NOT NULL,
    approval_timing DATETIME,
    STATUS          VARCHAR(50) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (leave_id) REFERENCES Leave (leave_id)
);

CREATE TABLE LeaveEntitlement
(
    employee_id   INT           NOT NULL,
    leave_type_id INT           NOT NULL,
    entitlement   DECIMAL(5, 2) NOT NULL,
    PRIMARY KEY (employee_id, leave_type_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (leave_type_id) REFERENCES Leave (leave_id)
);

CREATE TABLE LeaveDocument
(
    document_id      INT PRIMARY KEY IDENTITY (1, 1),
    leave_request_id INT          NOT NULL,
    file_path        VARCHAR(255) NOT NULL,
    uploaded_at      DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (leave_request_id) REFERENCES LeaveRequest (request_id)
);

CREATE TABLE ShiftSchedule
(
    shift_id       INT PRIMARY KEY IDENTITY (1, 1),
    name           VARCHAR(50) NOT NULL,
    TYPE           VARCHAR(50) NOT NULL,
    start_time     TIME        NOT NULL,
    end_time       TIME        NOT NULL,
    break_duration INT,
    shift_date     DATE,
    STATUS         VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE Exception
(
    exception_id INT PRIMARY KEY IDENTITY (1, 1),
    name         VARCHAR(100) NOT NULL,
    category     VARCHAR(50)  NOT NULL,
    date         DATE         NOT NULL,
    STATUS       VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE ShiftAssignment
(
    assignment_id INT PRIMARY KEY IDENTITY (1, 1),
    employee_id   INT         NOT NULL,
    shift_id      INT         NOT NULL,
    start_date    DATE        NOT NULL,
    end_date      DATE        NULL,
    STATUS        VARCHAR(50) NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (shift_id) REFERENCES ShiftSchedule (shift_id)
);

CREATE TABLE Employee_Exception
(
    employee_id  INT NOT NULL,
    exception_id INT NOT NULL,
    PRIMARY KEY (employee_id, exception_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (exception_id) REFERENCES Exception (exception_id)
);

CREATE TABLE Attendance
(
    attendance_id INT PRIMARY KEY IDENTITY (1, 1),
    employee_id   INT NOT NULL,
    shift_id      INT NOT NULL,
    entry_time    DATETIME,
    exit_time     DATETIME,
    duration      INT,
    login_method  VARCHAR(50),
    logout_method VARCHAR(50),
    exception_id  INT,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (shift_id) REFERENCES ShiftSchedule (shift_id),
    FOREIGN KEY (exception_id) REFERENCES Exception (exception_id)
);

CREATE TABLE AttendanceLog
(
    attendance_log_id INT NOT NULL IDENTITY (1,1),
    attendance_id     INT NOT NULL,
    actor             INT NOT NULL,
    timestamp         DATETIME DEFAULT GETDATE(),
    reason            varchar(max),
    PRIMARY KEY (attendance_log_id, attendance_id),
    FOREIGN KEY (attendance_id) REFERENCES Attendance (attendance_id),
    FOREIGN KEY (actor) REFERENCES Employee (employee_id)
);
CREATE TABLE AttendanceCorrectionRequest
(
    request_id      INT PRIMARY KEY IDENTITY (1, 1),
    employee_id     INT          NOT NULL,
    date            DATE         NOT NULL,
    correction_type VARCHAR(50)  NOT NULL,
    reason          varchar(max) NOT NULL,
    STATUS          VARCHAR(50)  NOT NULL,
    recorded_by     INT          NOT NULL,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (recorded_by) REFERENCES Employee (employee_id)
);

CREATE TABLE Device
(
    device_id   INT PRIMARY KEY IDENTITY (1, 1),
    device_type VARCHAR(50) NOT NULL,
    terminal_id VARCHAR(50),
    latitude    DECIMAL(10, 7),
    longitude   DECIMAL(10, 7),
    employee_id INT,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE AttendanceSource
(
    attendance_id INT         NOT NULL,
    device_id     INT         NOT NULL,
    source_type   VARCHAR(50) NOT NULL,
    latitude      DECIMAL(10, 7),
    longitude     DECIMAL(10, 7),
    recorded_at   DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (attendance_id, device_id),
    FOREIGN KEY (attendance_id) REFERENCES Attendance (attendance_id),
    FOREIGN KEY (device_id) REFERENCES Device (device_id)
);

CREATE TABLE ShiftCycle
(
    cycle_id    INT PRIMARY KEY IDENTITY (1, 1),
    cycle_name  VARCHAR(50) NOT NULL,
    description varchar(max)
);

CREATE TABLE ShiftCycleAssignment
(
    cycle_id     INT NOT NULL,
    shift_id     INT NOT NULL,
    order_number INT NOT NULL,
    PRIMARY KEY (cycle_id, shift_id),
    FOREIGN KEY (cycle_id) REFERENCES ShiftCycle (cycle_id),
    FOREIGN KEY (shift_id) REFERENCES ShiftSchedule (shift_id)
);

CREATE TABLE Payroll
(
    payroll_id    INT PRIMARY KEY IDENTITY (1, 1),
    employee_id   INT            NOT NULL,
    taxes         DECIMAL(10, 2),
    period_start  DATE           NOT NULL,
    period_end    DATE           NOT NULL,
    base_amount   DECIMAL(10, 2) NOT NULL,
    adjustments   DECIMAL(10, 2) DEFAULT 0,
    contributions DECIMAL(10, 2) DEFAULT 0,
    actual_pay    DECIMAL(10, 2) NOT NULL,
    net_salary    DECIMAL(10, 2) NOT NULL,
    payment_date  DATE,
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id)
);

CREATE TABLE HourlySalaryType
(
    salary_type_id    INT PRIMARY KEY,
    hourly_rate       DECIMAL(10, 2) NOT NULL,
    max_monthly_hours INT            NOT NULL,
    FOREIGN KEY (salary_type_id) REFERENCES SalaryType (salary_type_id)
);

CREATE TABLE MonthlySalaryType
(
    salary_type_id      INT PRIMARY KEY,
    tax_rule            varchar(max) NOT NULL,
    contribution_scheme varchar(max) NOT NULL,
    FOREIGN KEY (salary_type_id) REFERENCES SalaryType (salary_type_id)
);

CREATE TABLE ContractSalaryType
(
    salary_type_id      INT PRIMARY KEY,
    contract_value      DECIMAL(10, 2) NOT NULL,
    installment_details varchar(max)   NOT NULL,
    FOREIGN KEY (salary_type_id) REFERENCES SalaryType (salary_type_id)
);

CREATE TABLE AllowanceDeduction
(
    ad_id       INT PRIMARY KEY IDENTITY (1, 1),
    payroll_id  INT            NOT NULL,
    employee_id INT            NOT NULL,
    TYPE        VARCHAR(50)    NOT NULL,
    amount      DECIMAL(10, 2) NOT NULL,
    currency    VARCHAR(50)    NOT NULL,
    duration    VARCHAR(50),
    timezone    VARCHAR(50),
    FOREIGN KEY (payroll_id) REFERENCES Payroll (payroll_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (currency) REFERENCES Currency (CurrencyName)
);

CREATE TABLE PayrollPolicy
(
    policy_id      INT PRIMARY KEY IDENTITY (1, 1),
    effective_date DATE        NOT NULL,
    TYPE           VARCHAR(50) NOT NULL,
    description    varchar(max)
);

CREATE TABLE OvertimePolicy
(
    policy_id               INT PRIMARY KEY,
    weekday_rate_multiplier DECIMAL(3, 2) NOT NULL,
    weekend_rate_multiplier DECIMAL(3, 2) NOT NULL,
    max_hours_per_month     INT           NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES PayrollPolicy (policy_id)
);

CREATE TABLE LatenessPolicy
(
    policy_id         INT PRIMARY KEY,
    grace_period_mins INT            NOT NULL,
    deduction_rate    DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES PayrollPolicy (policy_id)
);

CREATE TABLE BonusPolicy
(
    policy_id            INT PRIMARY KEY,
    bonus_type           VARCHAR(50)  NOT NULL,
    eligibility_criteria varchar(max) NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES PayrollPolicy (policy_id)
);

CREATE TABLE DeductionPolicy
(
    policy_id        INT PRIMARY KEY,
    deduction_reason VARCHAR(100) NOT NULL,
    calculation_mode VARCHAR(100) NOT NULL,
    FOREIGN KEY (policy_id) REFERENCES PayrollPolicy (policy_id)
);

CREATE TABLE PayrollPolicy_ID
(
    payroll_id INT NOT NULL,
    policy_id  INT NOT NULL,
    PRIMARY KEY (payroll_id, policy_id),
    FOREIGN KEY (payroll_id) REFERENCES Payroll (payroll_id),
    FOREIGN KEY (policy_id) REFERENCES PayrollPolicy (policy_id)
);

CREATE TABLE Payroll_Log
(
    payroll_log_id    INT PRIMARY KEY IDENTITY (1, 1),
    payroll_id        INT          NOT NULL,
    actor             INT          NOT NULL,
    change_date       DATETIME DEFAULT GETDATE(),
    modification_type VARCHAR(100) NOT NULL,
    FOREIGN KEY (payroll_id) REFERENCES Payroll (payroll_id),
    FOREIGN KEY (actor) REFERENCES Employee (employee_id)
);

CREATE TABLE PayrollPeriod
(
    payroll_period_id INT PRIMARY KEY IDENTITY (1, 1),
    payroll_id        INT         NOT NULL,
    start_date        DATE        NOT NULL,
    end_date          DATE        NOT NULL,
    STATUS            VARCHAR(50) NOT NULL,
    FOREIGN KEY (payroll_id) REFERENCES Payroll (payroll_id)
);

CREATE TABLE Notification
(
    notification_id   INT PRIMARY KEY IDENTITY (1, 1),
    message_content   varchar(max) NOT NULL,
    timestamp         DATETIME DEFAULT GETDATE(),
    urgency           VARCHAR(50)  NOT NULL,
    read_status       BIT      DEFAULT 0,
    notification_type VARCHAR(50)
);

CREATE TABLE Employee_Notification
(
    employee_id     INT NOT NULL,
    notification_id INT NOT NULL,
    delivery_status VARCHAR(50),
    delivered_at    DATETIME,
    PRIMARY KEY (employee_id, notification_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (notification_id) REFERENCES Notification (notification_id)
);

CREATE TABLE EmployeeHierarchy
(
    employee_id     INT NOT NULL,
    manager_id      INT NOT NULL,
    hierarchy_level INT NOT NULL,
    PRIMARY KEY (employee_id, manager_id),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (manager_id) REFERENCES Employee (employee_id)
);

CREATE TABLE ApprovalWorkflow
(
    workflow_id      INT PRIMARY KEY IDENTITY (1, 1),
    workflow_type    VARCHAR(50) NOT NULL,
    threshold_amount DECIMAL(10, 2),
    approver_role    VARCHAR(50),
    created_by       INT         NOT NULL,
    STATUS           VARCHAR(50) NOT NULL,
    FOREIGN KEY (created_by) REFERENCES Employee (employee_id)
);

CREATE TABLE ApprovalWorkflowStep
(
    workflow_id     INT          NOT NULL,
    step_number     INT          NOT NULL,
    role_id         INT          NOT NULL,
    action_required VARCHAR(100) NOT NULL,
    PRIMARY KEY (workflow_id, step_number),
    FOREIGN KEY (workflow_id) REFERENCES ApprovalWorkflow (workflow_id),
    FOREIGN KEY (role_id) REFERENCES Role (role_id)
);

CREATE TABLE ManagerNotes
(
    note_id      INT PRIMARY KEY IDENTITY (1, 1),
    employee_id  INT          NOT NULL,
    manager_id   INT          NOT NULL,
    note_content varchar(max) NOT NULL,
    created_at   DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (employee_id) REFERENCES Employee (employee_id),
    FOREIGN KEY (manager_id) REFERENCES Employee (employee_id)
);
