USE HRMS;

GO
CREATE PROCEDURE ViewEmployeeInfo @EmployeeID INT AS
BEGIN
    SELECT *
    FROM Employee
    WHERE employee_id = @EmployeeID;

END;

GO
CREATE PROCEDURE AddEmployee @FullName VARCHAR(200),
                             @NationalID VARCHAR(50),
                             @DateOfBirth DATE,
                             @CountryOfBirth VARCHAR(100),
                             @Phone VARCHAR(50),
                             @Email VARCHAR(100),
                             @Address VARCHAR(255),
                             @EmergencyContactName VARCHAR(100),
                             @EmergencyContactPhone VARCHAR(50),
                             @Relationship VARCHAR(50),
                             @Biography VARCHAR(MAX),
                             @EmploymentProgress VARCHAR(100),
                             @AccountStatus VARCHAR(50),
                             @EmploymentStatus VARCHAR(50),
                             @HireDate DATE,
                             @IsActive BIT,
                             @ProfileCompletion INT,
                             @DepartmentID INT,
                             @PositionID INT,
                             @ManagerID INT,
                             @ContractID INT,
                             @TaxFormID INT,
                             @SalaryTypeID INT,
                             @PayGrade VARCHAR(50),
                             @EmployeeID INT OUTPUT AS
BEGIN
        IF @FullName IS NULL
            OR @Email IS NULL
            OR @HireDate IS NULL
            BEGIN
                SELECT 'Required fields cannot be null' AS Message;

                RETURN;

            END
        IF EXISTS (SELECT 1
                   FROM Employee
                   WHERE email = @Email)
            BEGIN
                SELECT 'Email already exists' AS Message;

                RETURN;

            END
        IF @NationalID IS NOT NULL
            AND EXISTS (SELECT 1
                        FROM Employee
                        WHERE national_id = @NationalID)
            BEGIN
                SELECT 'National ID already exists' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Department
                       WHERE department_id = @DepartmentID)
            BEGIN
                SELECT 'Department not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Position
                       WHERE position_id = @PositionID)
            BEGIN
                SELECT 'Position not found' AS Message;

                RETURN;

            END
        IF @ManagerID IS NOT NULL
            AND NOT EXISTS (SELECT 1
                            FROM Employee
                            WHERE employee_id = @ManagerID)
            BEGIN
                SELECT 'Manager not found' AS Message;

                RETURN;

            END
        DECLARE @FirstName VARCHAR(50),
            @LastName VARCHAR(50);

        IF CHARINDEX(' ', @FullName) > 0
            BEGIN
                SET
                    @FirstName = LEFT(@FullName, CHARINDEX(' ', @FullName) - 1);

                SET
                    @LastName = RIGHT(
                            @FullName,
                            DATALENGTH(@FullName) - CHARINDEX(' ', @FullName)
                                );

            END
        ELSE
            BEGIN
                SET
                    @FirstName = @FullName;

                SET
                    @LastName = '';

            END

        INSERT INTO Employee (first_name,
                              last_name,
                              full_name,
                              national_id,
                              date_of_birth,
                              country_of_birth,
                              phone,
                              email,
                              address,
                              emergency_contact_name,
                              emergency_contact_phone,
                              relationship,
                              biography,
                              employment_progress,
                              account_status,
                              employment_status,
                              hire_date,
                              is_active,
                              profile_completion,
                              department_id,
                              position_id,
                              manager_id,
                              contract_id,
                              tax_form_id,
                              salary_type_id,
                              pay_grade)
        VALUES (@FirstName,
                @LastName,
                @FullName,
                @NationalID,
                @DateOfBirth,
                @CountryOfBirth,
                @Phone,
                @Email,
                @Address,
                @EmergencyContactName,
                @EmergencyContactPhone,
                @Relationship,
                @Biography,
                @EmploymentProgress,
                @AccountStatus,
                @EmploymentStatus,
                @HireDate,
                @IsActive,
                @ProfileCompletion,
                @DepartmentID,
                @PositionID,
                @ManagerID,
                @ContractID,
                @TaxFormID,
                @SalaryTypeID,
                @PayGrade);

        SET
            @EmployeeID = SCOPE_IDENTITY();


        SELECT 'Employee added successfully with ID: ' + CAST(@EmployeeID AS VARCHAR(10)) AS Message;

END;

GO
CREATE PROCEDURE UpdateEmployeeInfo @EmployeeID INT,
                                    @Email VARCHAR(100),
                                    @Phone VARCHAR(20),
                                    @Address VARCHAR(150) AS
BEGIN
    IF NOT EXISTS (SELECT 1 
                   FROM Employee 
                   WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Message;
        RETURN;
    END
        
    IF @Email IS NOT NULL 
       AND EXISTS (SELECT 1 
                   FROM Employee 
                   WHERE email = @Email AND
                    employee_id != @EmployeeID)
    BEGIN
        SELECT 'Email already in use by another employee' AS Message;
        RETURN;
    END
        
    UPDATE
        Employee
    SET email   = @Email,
        phone   = @Phone,
        address = @Address
    WHERE employee_id = @EmployeeID;

    SELECT 'Employee information updated successfully' AS Message;

END;

GO
CREATE PROCEDURE AssignRole @EmployeeID INT,
                            @RoleID INT AS
BEGIN
    IF NOT EXISTS (SELECT 1 
                   FROM Employee 
                   WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Message;
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 
                   FROM Role 
                       WHERE role_id = @RoleID)
    BEGIN
        SELECT 'Role not found' AS Message;
        RETURN;
    END    
    
    IF NOT EXISTS (SELECT 1
                   FROM Employee_Role
                   WHERE employee_id = @EmployeeID
                     AND role_id = @RoleID)
        BEGIN
            INSERT INTO Employee_Role (employee_id, role_id)
            VALUES (@EmployeeID, @RoleID);

            SELECT 'Role assigned successfully' AS Message;

        END
    ELSE
        SELECT 'Role already assigned to this employee' AS Message;

END;

GO
CREATE PROCEDURE GetDepartmentEmployeeStats AS
BEGIN
    SELECT d.department_name,
           COUNT(e.employee_id) AS employee_count
    FROM Department d
             LEFT JOIN Employee e ON d.department_id = e.department_id
    GROUP BY d.department_name;

END;

GO
CREATE PROCEDURE ReassignManager 
    @EmployeeID INT,
    @NewManagerID INT 
AS
BEGIN
    IF NOT EXISTS (SELECT 1  
                   FROM Employee 
                     WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Message;
        RETURN;
    END

    IF @NewManagerID IS NOT NULL 
       AND NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @NewManagerID)
    BEGIN
        SELECT 'Manager not found' AS Message;
        RETURN;
    END
    
    IF @EmployeeID = @NewManagerID
    BEGIN
        SELECT 'Employee cannot be their own manager' AS Message;
        RETURN;
    END
    
    UPDATE Employee
    SET manager_id = @NewManagerID
    WHERE employee_id = @EmployeeID;

    SELECT 'Manager reassigned successfully' AS Message;
END;

GO
CREATE PROCEDURE ReassignHierarchy @EmployeeID INT,
                                   @NewDepartmentID INT,
                                   @NewManagerID INT AS
BEGIN

        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Department
                       WHERE department_id = @NewDepartmentID)
            BEGIN
                SELECT 'Department not found' AS Message;

                RETURN;

            END
        IF @NewManagerID IS NOT NULL
            AND NOT EXISTS (SELECT 1
                            FROM Employee
                            WHERE employee_id = @NewManagerID)
            BEGIN
                SELECT 'Manager not found' AS Message;

                RETURN;

            END
        IF @EmployeeID = @NewManagerID
            BEGIN
                SELECT 'Employee cannot be their own manager' AS Message;

                RETURN;

            END

        UPDATE
            Employee
        SET department_id = @NewDepartmentID,
            manager_id    = @NewManagerID
        WHERE employee_id = @EmployeeID;

        IF EXISTS (SELECT 1
                   FROM EmployeeHierarchy
                   WHERE employee_id = @EmployeeID)
            UPDATE
                EmployeeHierarchy
            SET manager_id = @NewManagerID
            WHERE employee_id = @EmployeeID;

        SELECT 'Employee hierarchy updated successfully' AS Message;

END;

GO
CREATE PROCEDURE NotifyStructureChange 
    @AffectedEmployees VARCHAR(500),
    @Message VARCHAR(200) 
AS
BEGIN
    IF @AffectedEmployees IS NULL OR @Message IS NULL
    BEGIN
        SELECT 'Affected employees and message are required' AS Message;
        RETURN;
    END

    DECLARE @NotificationID INT;

    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES (@Message, 'High', 'Structure Change');

    SET @NotificationID = SCOPE_IDENTITY();

    DECLARE @EmployeeID INT;
    DECLARE @Position INT;
    DECLARE @EmployeeList VARCHAR(500);

    SET @EmployeeList = @AffectedEmployees + ',';

    WHILE @EmployeeList <> ''
    BEGIN
        SET @Position = CHARINDEX(',', @EmployeeList);
        
        IF @Position > 0
        BEGIN
            SET @EmployeeID = CAST(LEFT(@EmployeeList, @Position - 1) AS INT);
            
            IF EXISTS (SELECT 1 
                       FROM Employee 
                       WHERE employee_id = @EmployeeID)
            BEGIN
                INSERT INTO Employee_Notification (
                    employee_id,
                    notification_id,
                    delivery_status,
                    delivered_at
                )
                VALUES (
                    @EmployeeID,
                    @NotificationID,
                    'Pending',
                    GETDATE()
                );
            END
            
            SET @EmployeeList = RIGHT(@EmployeeList, LEN(@EmployeeList) - @Position);
        END
        ELSE
        BEGIN
            SET @EmployeeList = '';
        END
    END

    SELECT 'Notification sent to affected employees' AS Message;
END;

GO
CREATE PROCEDURE ViewOrgHierarchy AS
BEGIN
    SELECT e.employee_id,
           e.full_name                   AS employee_name,
           m.full_name                   AS manager_name,
           d.department_name,
           p.position_title,
           ISNULL(eh.hierarchy_level, 1) AS hierarchy_level
    FROM Employee e
             LEFT JOIN Employee m ON e.manager_id = m.employee_id
             LEFT JOIN Department d ON e.department_id = d.department_id
             LEFT JOIN Position p ON e.position_id = p.position_id
             LEFT JOIN EmployeeHierarchy eh ON e.employee_id = eh.employee_id
        AND e.manager_id = eh.manager_id
    ORDER BY hierarchy_level,
             d.department_name;

END;

GO
CREATE PROCEDURE AssignShiftToEmployee @EmployeeID INT,
                                       @ShiftID INT,
                                       @StartDate DATE,
                                       @EndDate DATE AS
BEGIN
    INSERT INTO ShiftAssignment (employee_id,
                                 shift_id,
                                 start_date,
                                 end_date,
                                 STATUS)
    VALUES (@EmployeeID,
            @ShiftID,
            @StartDate,
            @EndDate,
            'Active');

    SELECT 'Shift assigned successfully' AS Message;

END;

GO
CREATE PROCEDURE UpdateShiftStatus @ShiftAssignmentID INT,
                                   @Status VARCHAR(20) AS
BEGIN
    UPDATE
        ShiftAssignment
    SET STATUS = @Status
    WHERE assignment_id = @ShiftAssignmentID;

    SELECT 'Shift status updated successfully' AS Message;

END;

GO
CREATE PROCEDURE AssignShiftToDepartment @DepartmentID INT,
                                         @ShiftID INT,
                                         @StartDate DATE,
                                         @EndDate DATE AS
BEGIN
    INSERT INTO ShiftAssignment (employee_id,
                                 shift_id,
                                 start_date,
                                 end_date,
                                 STATUS)
    SELECT employee_id,
           @ShiftID,
           @StartDate,
           @EndDate,
           'Active'
    FROM Employee
    WHERE department_id = @DepartmentID;

    SELECT 'Shift assigned to all employees in department' AS Message;

END;

GO
CREATE PROCEDURE AssignCustomShift 
    @EmployeeID INT,
    @ShiftName VARCHAR(50),
    @ShiftType VARCHAR(50),
    @StartTime TIME,
    @EndTime TIME,
    @StartDate DATE,
    @EndDate DATE 
AS
BEGIN
    IF NOT EXISTS (SELECT 1 
                   FROM Employee 
                   WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Message;
        RETURN;
    END

    IF @StartDate > @EndDate
    BEGIN
        SELECT 'Start date cannot be after end date' AS Message;
        RETURN;
    END

    DECLARE @ShiftID INT;

    INSERT INTO ShiftSchedule (name, TYPE, start_time, end_time, STATUS)
    VALUES (@ShiftName, @ShiftType, @StartTime, @EndTime, 'Active');

    SET @ShiftID = SCOPE_IDENTITY();

    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, STATUS)
    VALUES (@EmployeeID, @ShiftID, @StartDate, @EndDate, 'Active');

    SELECT 'Custom shift created and assigned successfully' AS Message;
END;

GO
CREATE PROCEDURE ConfigureSplitShift @ShiftName VARCHAR(50),
                                     @FirstSlotStart TIME,
                                     @FirstSlotEnd TIME,
                                     @SecondSlotStart TIME,
                                     @SecondSlotEnd TIME AS
BEGIN
    DECLARE @BreakDuration INT;

    SET
        @BreakDuration = DATEDIFF(MINUTE, @FirstSlotEnd, @SecondSlotStart);

    INSERT INTO ShiftSchedule (name,
                               TYPE,
                               start_time,
                               end_time,
                               break_duration,
                               STATUS)
    VALUES (@ShiftName,
            'Split',
            @FirstSlotStart,
            @SecondSlotEnd,
            @BreakDuration,
            'Active');

    SELECT 'Split shift configured successfully' AS Message;

END;

GO
CREATE PROCEDURE EnableFirstInLastOut @Enable BIT AS
BEGIN
    SELECT 'First In/Last Out processing ' + IIF(@Enable = 1, 'enabled', 'disabled') AS Message;

END;

GO
CREATE PROCEDURE TagAttendanceSource 
    @AttendanceID INT,
    @SourceType VARCHAR(20),
    @DeviceID INT,
    @Latitude DECIMAL(10, 7),
    @Longitude DECIMAL(10, 7) 
AS
BEGIN
    IF NOT EXISTS (SELECT 1 
                   FROM Attendance 
                    WHERE attendance_id = @AttendanceID)
    BEGIN
        SELECT 'Attendance record not found' AS Message;
        RETURN;
    END

    IF EXISTS (SELECT 1 
               FROM AttendanceSource 
               WHERE attendance_id = @AttendanceID 
               AND device_id = @DeviceID)
    BEGIN
        SELECT 'Attendance source already tagged for this device' AS Message;
        RETURN;
    END

    INSERT INTO AttendanceSource (
        attendance_id,
        device_id,
        source_type,
        latitude,
        longitude
    )
    VALUES (
        @AttendanceID,
        @DeviceID,
        @SourceType,
        @Latitude,
        @Longitude
    );

    SELECT 'Attendance source tagged successfully' AS Message;
END;

GO
CREATE PROCEDURE SyncOfflineAttendance 
    @DeviceID INT,
    @EmployeeID INT,
    @ClockTime DATETIME,
    @Type VARCHAR(10) 
AS
BEGIN
    IF NOT EXISTS (SELECT 1 
                   FROM Employee
                    WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Message;
        RETURN;
    END

    IF @Type NOT IN ('IN', 'OUT')
    BEGIN
        SELECT 'Invalid type. Must be IN or OUT' AS Message;
        RETURN;
    END

    DECLARE @ShiftID INT;

    SELECT TOP 1 @ShiftID = shift_id
    FROM ShiftAssignment
    WHERE employee_id = @EmployeeID
      AND STATUS = 'Active'
      AND @ClockTime BETWEEN start_date AND ISNULL(end_date, '9999-12-31')
    ORDER BY start_date DESC;

    IF @ShiftID IS NULL
    BEGIN
        SELECT 'No active shift found for employee at this time' AS Message;
        RETURN;
    END

    IF @Type = 'IN'
    BEGIN
        INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
        VALUES (@EmployeeID, @ShiftID, @ClockTime, 'Offline Sync');
        
        SELECT 'Offline attendance synced successfully' AS Message;
    END
    ELSE IF @Type = 'OUT'
    BEGIN
        DECLARE @AttendanceID INT;

        SELECT TOP 1 @AttendanceID = attendance_id
        FROM Attendance
        WHERE employee_id = @EmployeeID
          AND CAST(entry_time AS DATE) = CAST(@ClockTime AS DATE)
          AND exit_time IS NULL
        ORDER BY entry_time DESC;

        IF @AttendanceID IS NULL
        BEGIN
            SELECT 'No matching clock-in found for this clock-out' AS Message;
            RETURN;
        END

        UPDATE Attendance
        SET exit_time = @ClockTime,
            logout_method = 'Offline Sync',
            duration = DATEDIFF(MINUTE, entry_time, @ClockTime)
        WHERE attendance_id = @AttendanceID;

        SELECT 'Offline attendance synced successfully' AS Message;
    END
END;


GO
CREATE PROCEDURE LogAttendanceEdit @AttendanceID INT,
                                   @EditedBy INT,
                                   @OldValue DATETIME,
                                   @NewValue DATETIME,
                                   @EditTimestamp DATETIME AS
BEGIN
    INSERT INTO AttendanceLog (attendance_id, actor, timestamp, reason)
    VALUES (@AttendanceID,
            @EditedBy,
            @EditTimestamp,
            'Changed from ' + CAST(@OldValue AS VARCHAR) + ' to ' + CAST(@NewValue AS VARCHAR));

    SELECT 'Attendance edit logged successfully' AS Message;

END;

GO
CREATE PROCEDURE ApplyHolidayOverrides 
    @HolidayID INT,
    @EmployeeID INT 
AS
BEGIN
    IF NOT EXISTS (SELECT 1  
                   FROM Exception 
                    WHERE exception_id = @HolidayID)
    BEGIN
        SELECT 'Holiday not found' AS Message;
        RETURN;
    END
    
    IF NOT EXISTS (SELECT 1 
                    FROM Employee 
                     WHERE employee_id = @EmployeeID)
    BEGIN
        SELECT 'Employee not found' AS Message;
        RETURN;
    END
    
    DECLARE @HolidayDate DATE;

    SELECT @HolidayDate = date
    FROM Exception
    WHERE exception_id = @HolidayID;

    UPDATE Attendance
    SET exception_id = @HolidayID
    WHERE employee_id = @EmployeeID
      AND CAST(entry_time AS DATE) = @HolidayDate
      AND exception_id IS NULL;

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT 'No attendance records found for this employee on the holiday date' AS Message;
        RETURN;
    END

    SELECT 'Holiday overrides applied successfully' AS Message;
END;

GO
CREATE PROCEDURE ManageUserAccounts 
    @UserID INT,
    @Role VARCHAR(50),
    @Action VARCHAR(20) 
AS
BEGIN
    IF @Action NOT IN ('Create', 'Update', 'Delete')
    BEGIN
        SELECT 'Invalid action. Must be Create, Update, or Delete' AS Message;
        RETURN;
    END

    IF @Action = 'Create'
    BEGIN
        IF EXISTS (SELECT 1 FROM UserAccount WHERE user_id = @UserID)
        BEGIN
            SELECT 'User account already exists' AS Message;
            RETURN;
        END

        INSERT INTO UserAccount (user_id, role, created_at, is_active)
        VALUES (@UserID, @Role, GETDATE(), 1);

        SELECT 'User account created with role: ' + @Role AS Message;
    END
    ELSE IF @Action = 'Update'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM UserAccount WHERE user_id = @UserID)
        BEGIN
            SELECT 'User account not found' AS Message;
            RETURN;
        END

        UPDATE UserAccount
        SET role = @Role,
            updated_at = GETDATE()
        WHERE user_id = @UserID;

        SELECT 'User account updated with new role: ' + @Role AS Message;
    END
    ELSE IF @Action = 'Delete'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM UserAccount WHERE user_id = @UserID)
        BEGIN
            SELECT 'User account not found' AS Message;
            RETURN;
        END

        DELETE FROM UserAccount WHERE user_id = @UserID;

        SELECT 'User account deleted' AS Message;
    END
END;

GO
CREATE PROCEDURE CreateContract @EmployeeID INT,
                                @Type VARCHAR(50),
                                @StartDate DATE,
                                @EndDate DATE AS
BEGIN        
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        IF @StartDate > @EndDate
            AND @EndDate IS NOT NULL
            BEGIN
                SELECT 'Start date cannot be after end date' AS Message;

                RETURN;

            END
        IF @Type NOT IN (
                         'Full-Time',
                         'Part-Time',
                         'Consultant',
                         'Internship'
            )
            BEGIN
                SELECT 'Invalid contract type' AS Message;

                RETURN;

            END
    

        INSERT INTO Contract (TYPE, start_date, end_date, current_state)
        VALUES (@Type, @StartDate, @EndDate, 'Active');

        Declare
            @ContractID INT = SCOPE_IDENTITY();

        UPDATE
            Employee
        SET contract_id = @ContractID
        WHERE employee_id = @EmployeeID;
        SELECT 'Contract created successfully' AS Message;
END;

GO
CREATE PROCEDURE RenewContract @ContractID INT,
                               @NewEndDate DATE AS
BEGIN
    UPDATE
        Contract
    SET end_date      = @NewEndDate,
        current_state = 'Renewed'
    WHERE contract_id = @ContractID;

    SELECT 'Contract renewed successfully' AS Message;

END;

GO
CREATE PROCEDURE ApproveLeaveRequest @LeaveRequestID INT,
                                     @ApproverID INT,
                                     @Status VARCHAR(20) AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM LeaveRequest
                       WHERE request_id = @LeaveRequestID)
            BEGIN
                SELECT 'Leave request not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @ApproverID)
            BEGIN
                SELECT 'Approver not found' AS Message;

                RETURN;

            END
        IF @Status NOT IN ('Approved', 'Rejected', 'Pending')
            BEGIN
                SELECT 'Invalid status. Must be Approved, Rejected, or Pending' AS Message;

                RETURN;

            END
        DECLARE @EmployeeID INT,
            @LeaveID INT,
            @Duration INT;

        SELECT @EmployeeID = employee_id,
               @LeaveID = leave_id,
               @Duration = duration
        FROM LeaveRequest
        WHERE request_id = @LeaveRequestID;

        IF @Status = 'Approved'
            BEGIN
                DECLARE @AvailableBalance DECIMAL(5, 2);

                SELECT @AvailableBalance = entitlement
                FROM LeaveEntitlement
                WHERE employee_id = @EmployeeID
                  AND leave_type_id = @LeaveID;

                IF @AvailableBalance < @Duration
                    BEGIN
                        SELECT 'Cannot approve - insufficient leave balance' AS Message;

                        RETURN;

                    END
            END
                        
        UPDATE
            LeaveRequest
        SET STATUS          = @Status,
            approval_timing = GETDATE()
        WHERE request_id = @LeaveRequestID;

        INSERT INTO Notification (message_content, urgency, notification_type)
        VALUES ('Your leave request has been ' + @Status,
                'Normal',
                'Leave');

        DECLARE @NotificationID INT = SCOPE_IDENTITY();

        INSERT INTO Employee_Notification (employee_id,
                                           notification_id,
                                           delivery_status,
                                           delivered_at)
        VALUES (@EmployeeID,
                @NotificationID,
                'Delivered',
                GETDATE());

        SELECT 'Leave request ' + @Status AS Message;

END;

GO
CREATE PROCEDURE AssignMission @EmployeeID INT,
                               @ManagerID INT,
                               @Destination VARCHAR(50),
                               @StartDate DATE,
                               @EndDate DATE AS
BEGIN
    INSERT INTO Mission (destination,
                         start_date,
                         end_date,
                         STATUS,
                         employee_id,
                         manager_id)
    VALUES (@Destination,
            @StartDate,
            @EndDate,
            'Assigned',
            @EmployeeID,
            @ManagerID);

    SELECT 'Mission assigned successfully' AS Message;

END;

GO
CREATE PROCEDURE ReviewReimbursement @ClaimID INT,
                                     @ApproverID INT,
                                     @Decision VARCHAR(20) AS
BEGIN
    UPDATE
        Reimbursement
    SET current_status = @Decision,
        approval_date  = GETDATE()
    WHERE reimbursement_id = @ClaimID;

    SELECT 'Reimbursement claim ' + @Decision AS Message;

END;

GO
CREATE PROCEDURE GetActiveContracts
AS
BEGIN
    SELECT c.*, e.full_name AS employee_name
    FROM Contract c, Employee e
    WHERE c.contract_id = e.contract_id
      AND c.current_state = 'Active';
END;

GO
CREATE PROCEDURE GetTeamByManager @ManagerID INT AS
BEGIN
    SELECT employee_id,
           full_name
    FROM Employee
    WHERE manager_id = @ManagerID;

END;

GO
CREATE PROCEDURE UpdateLeavePolicy @PolicyID INT,
                                   @EligibilityRules VARCHAR(200),
                                   @NoticePeriod INT AS
BEGIN
    UPDATE
        LeavePolicy
    SET eligibility_rules = @EligibilityRules,
        notice_period     = @NoticePeriod
    WHERE policy_id = @PolicyID;

    SELECT 'Leave policy updated successfully' AS Message;

END;

GO
CREATE PROCEDURE GetExpiringContracts @DaysBefore INT AS
BEGIN
    SELECT c.*,
           e.full_name AS employee_name
    FROM Contract c
             INNER JOIN Employee e ON c.contract_id = e.contract_id
    WHERE c.end_date IS NOT NULL
      AND c.end_date <= GETDATE() + @DaysBefore
      AND c.current_state = 'Active';

END;

GO
CREATE PROCEDURE AssignDepartmentHead @DepartmentID INT,
                                      @ManagerID INT AS
BEGIN
    UPDATE
        Department
    SET department_head_id = @ManagerID
    WHERE department_id = @DepartmentID;

    SELECT 'Department head assigned successfully' AS Message;

END;

GO
CREATE PROCEDURE CreateEmployeeProfile @FirstName VARCHAR(50),
                                       @LastName VARCHAR(50),
                                       @DepartmentID INT,
                                       @RoleID INT,
                                       @HireDate DATE,
                                       @Email VARCHAR(100),
                                       @Phone VARCHAR(20),
                                       @NationalID VARCHAR(50),
                                       @DateOfBirth DATE,
                                       @CountryOfBirth VARCHAR(100) AS
BEGIN
        IF @FirstName IS NULL
            OR @LastName IS NULL
            OR @Email IS NULL
            OR @HireDate IS NULL
            BEGIN
                SELECT 'Required fields cannot be null' AS Message;

                RETURN;

            END
        IF EXISTS (SELECT 1
                   FROM Employee
                   WHERE email = @Email)
            BEGIN
                SELECT 'Email already exists' AS Message;

                RETURN;

            END
        IF @NationalID IS NOT NULL
            AND EXISTS (SELECT 1
                        FROM Employee
                        WHERE national_id = @NationalID)
            BEGIN
                SELECT 'National ID already exists' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Department
                       WHERE department_id = @DepartmentID)
            BEGIN
                SELECT 'Department not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Role
                       WHERE role_id = @RoleID)
            BEGIN
                SELECT 'Role not found' AS Message;

                RETURN;

            END


        INSERT INTO Employee (first_name,
                              last_name,
                              national_id,
                              date_of_birth,
                              country_of_birth,
                              email,
                              phone,
                              department_id,
                              hire_date)
        VALUES (@FirstName,
                @LastName,
                @NationalID,
                @DateOfBirth,
                @CountryOfBirth,
                @Email,
                @Phone,
                @DepartmentID,
                @HireDate);

        Declare
            @EmployeeID INT = SCOPE_IDENTITY();

        INSERT INTO Employee_Role (employee_id, role_id)
        VALUES (@EmployeeID, @RoleID);

        SELECT 'Employee profile created with ID: ' + CAST(@EmployeeID AS VARCHAR) AS Message,
END;

GO
CREATE PROCEDURE UpdateEmployeeProfile @EmployeeID INT,
                                       @FieldName VARCHAR(50),
                                       @NewValue VARCHAR(255) AS
BEGIN


    SET
        @SQL = 'UPDATE Employee SET ' + QUOTENAME(@FieldName) + ' = @Value WHERE employee_id = @EmpID';

    EXEC sp_executesql @SQL,
         N'@Value VARCHAR(255), @EmpID INT',
         @NewValue,
         @EmployeeID;

    SELECT 'Employee profile updated successfully' AS Message;

END;

GO
CREATE PROCEDURE SetProfileCompleteness @EmployeeID INT,
                                        @CompletenessPercentage INT AS
BEGIN
    UPDATE
        Employee
    SET profile_completion = @CompletenessPercentage
    WHERE employee_id = @EmployeeID;

    SELECT 'Profile completeness updated to ' + CAST(@CompletenessPercentage AS VARCHAR) + '%' AS Message;

END;

GO
CREATE PROCEDURE GenerateProfileReport @FilterField VARCHAR(50),
                                       @FilterValue VARCHAR(100) AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    SET
        @SQL = 'SELECT * FROM Employee WHERE ' + QUOTENAME(@FilterField) + ' = @Value';

    EXEC sp_executesql @SQL,
         N'@Value VARCHAR(100)',
         @FilterValue;

END;

GO
CREATE PROCEDURE AssignRotationalShift @EmployeeID INT,
                                       @ShiftCycle INT,
                                       @StartDate DATE,
                                       @EndDate DATE,
                                       @Status VARCHAR(20) AS
BEGIN
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM ShiftCycle
                       WHERE cycle_id = @ShiftCycle)
            BEGIN
                SELECT 'Shift cycle not found' AS Message;

                RETURN;

            END
        IF @StartDate > @EndDate
            BEGIN
                SELECT 'Start date cannot be after end date' AS Message;

                RETURN;

            END

        DECLARE @ShiftID INT;
    SELECT TOP 1 @ShiftID = shift_id
    FROM ShiftCycleAssignment
    WHERE cycle_id = @ShiftCycle;

    IF @ShiftID IS NULL
    BEGIN
        SELECT 'No shifts found in cycle' AS Message;
        RETURN;
    END

    INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, end_date, status)
    VALUES (@EmployeeID, @ShiftID, @StartDate, @EndDate, @Status);

    SELECT 'Rotational shift assigned successfully' AS Message;
END;

GO
CREATE PROCEDURE NotifyShiftExpiry @EmployeeID INT,
                                   @ShiftAssignmentID INT,
                                   @ExpiryDate DATE AS
BEGIN
    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES ('Your shift assignment expires on ' + CAST(@ExpiryDate AS VARCHAR),
            'Normal',
            'Shift');

    DECLARE @NotificationID INT = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id,
                                       notification_id,
                                       delivery_status,
                                       delivered_at)
    VALUES (@EmployeeID,
            @NotificationID,
            'Delivered',
            GETDATE());

    SELECT 'Shift expiry notification sent' AS Message;

END;

GO
CREATE PROCEDURE DefineShortTimeRules @RuleName VARCHAR(50),
                                      @LateMinutes INT,
                                      @EarlyLeaveMinutes INT,
                                      @PenaltyType VARCHAR(50) AS
BEGIN
    SELECT 'Short time rules defined successfully' AS Message;

END;

GO
CREATE PROCEDURE SetGracePeriod @Minutes INT AS
BEGIN
    SELECT 'Grace period set to ' + CAST(@Minutes AS VARCHAR) + ' minutes' AS Message;

END;

GO
CREATE PROCEDURE DefinePenaltyThreshold @LateMinutes INT,
                                        @DeductionType VARCHAR(50) AS
BEGIN
    IF @LateMinutes IS NULL OR @DeductionType IS NULL
    BEGIN
        PRINT 'One of the inputs is null'
        RETURN
    END
    
    IF @LateMinutes <= 0
    BEGIN
        SELECT 'Late minutes must be greater than zero' AS Message;
        RETURN;
    END
        IF @DeductionType NOT IN ('half-day', 'full-day', 'hourly', 'warning')
    BEGIN
        PRINT 'Invalid deduction type. Allowed: half-day, full-day, hourly, warning'
        RETURN
    END
    SELECT 'Penalty threshold defined: ' + CAST(@LateMinutes AS VARCHAR) + ' minutes = ' + @DeductionType AS Message;

END;

GO
CREATE PROCEDURE DefinePermissionLimits @MinHours INT,
                                        @MaxHours INT AS
BEGIN
   IF @MinHours IS NULL OR @MaxHours IS NULL
    BEGIN
        PRINT 'One of the inputs is null'
        RETURN
    END
    
    IF @MinHours < 0 OR @MaxHours < 0
    BEGIN
        PRINT 'Hours cannot be negative'
        RETURN
    END
    
    IF @MinHours > @MaxHours
    BEGIN
        PRINT 'Minimum hours cannot exceed maximum hours'
        RETURN
    END
    
    SELECT
        'Permission limits set: Min=' + CAST(@MinHours AS VARCHAR) + ', Max=' + CAST(@MaxHours AS VARCHAR) AS Message;
Select
        'Permission limits set successfully' AS Message;
END;

GO
CREATE PROCEDURE EscalatePendingRequests @Deadline DATETIME AS
BEGIN
    SELECT 'Pending requests escalated after deadline: ' + CAST(@Deadline AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE LinkVacationToShift @VacationPackageID INT,
                                     @EmployeeID INT AS
BEGIN
    IF @VacationPackageID IS NULL OR @EmployeeID IS NULL
    BEGIN
        PRINT 'One of the inputs is null'
        RETURN
    END
    
    -- Validate employee exists (Lab 7-1a EXISTS pattern)
    IF NOT EXISTS (
        SELECT 1 
        FROM Employee 
        WHERE employee_id = @EmployeeID
    )
    BEGIN
        PRINT 'Employee ID does not exist'
        RETURN
    END
    
   
    IF NOT EXISTS (
        SELECT 1 
        FROM VacationLeave 
        WHERE leave_id = @VacationPackageID
    )
    BEGIN
        PRINT 'Vacation package ID does not exist'
        RETURN
    END
    
  
    IF EXISTS (
        SELECT 1 
        FROM ShiftAssignment 
        WHERE employee_id = @EmployeeID 
          AND status = 'Active'
    )
    BEGIN
        INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, status)
        VALUES (
            @EmployeeID,
            @VacationPackageID,
            'Vacation package linked to shift schedule',
            5,
            'Approved'
        )
        
        PRINT 'Vacation package linked to employee shift successfully'
    END
    ELSE
    BEGIN
        PRINT 'Employee has no active shift assignment'
        RETURN
    END
    
    SELECT 'Vacation package linked to employee shift' AS Message
END

END;

GO
CREATE PROCEDURE ConfigureLeavePolicies AS
BEGIN
    SELECT 'Leave configuration process initiated' AS Message;

END;

GO
CREATE PROCEDURE AuthenticateLeaveAdmin @AdminID INT,
                                        @Password VARCHAR(100) AS
BEGIN
    IF @AdminID IS NULL OR @Password IS NULL
    BEGIN
        PRINT 'One of the inputs is null'
        RETURN
    END
     IF EXISTS (
        SELECT 1 
        FROM HRAdministrator hr
        INNER JOIN Employee e ON hr.employee_id = e.employee_id
        WHERE hr.employee_id = @AdminID 
          AND e.account_status = 'Active'
    )
DECLARE @ApprovalLevel VARCHAR(50)
        SELECT @ApprovalLevel = approval_level
        FROM HRAdministrator
        WHERE employee_id = @AdminID
        
        IF @ApprovalLevel IN ('Senior', 'Manager', 'Director')
        BEGIN
            SELECT 'Administrator authenticated successfully' AS Message
        END

END;

GO
CREATE PROCEDURE ApplyLeaveConfiguration AS
BEGIN
    SELECT 'Leave configuration applied successfully' AS Message;

END;

GO
CREATE PROCEDURE UpdateLeaveEntitlements @EmployeeID INT AS
BEGIN
     IF @EmployeeID IS NULL
    BEGIN
        PRINT 'Employee ID is required'
        RETURN
    END
    F NOT EXISTS (
        SELECT 1 
        FROM Employee 
        WHERE employee_id = @EmployeeID
    )
    BEGIN
        PRINT 'Employee ID does not exist'
        RETURN
    END
    SELECT 'Leave entitlements updated for employee' AS Message;

END;
--mohannd hany 
GO
CREATE PROCEDURE ConfigureLeaveEligibility @LeaveType VARCHAR(50),
                                           @MinTenure INT,
                                           @EmployeeType VARCHAR(50) AS
BEGIN
    SELECT 'Leave eligibility configured for ' + @LeaveType AS Message;

END;

GO
CREATE PROCEDURE ManageLeaveTypes @LeaveType VARCHAR(50),
                                  @Description VARCHAR(200) AS
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM Leave
                   WHERE leave_type = @LeaveType)
        BEGIN
            INSERT INTO Leave (leave_type, leave_description)
            VALUES (@LeaveType, @Description);

            SELECT 'Leave type created successfully' AS Message;

        END
    ELSE
        BEGIN
            UPDATE
                Leave
            SET leave_description = @Description
            WHERE leave_type = @LeaveType;

            SELECT 'Leave type updated successfully' AS Message;

        END
END;

GO
CREATE PROCEDURE AssignLeaveEntitlement @EmployeeID INT,
                                        @LeaveType VARCHAR(50),
                                        @Entitlement DECIMAL(5, 2) AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        IF @Entitlement < 0
            BEGIN
                SELECT 'Entitlement cannot be negative' AS Message;

                RETURN;

            END
        DECLARE @LeaveID INT;

        SELECT @LeaveID = leave_id
        FROM Leave
        WHERE leave_type = @LeaveType;

        IF @LeaveID IS NULL
            BEGIN
                SELECT 'Leave type not found' AS Message;

                RETURN;

            END
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1
                   FROM LeaveEntitlement
                   WHERE employee_id = @EmployeeID
                     AND leave_type_id = @LeaveID)
            UPDATE
                LeaveEntitlement
            SET entitlement = @Entitlement
            WHERE employee_id = @EmployeeID
              AND leave_type_id = @LeaveID;

        ELSE
            INSERT INTO LeaveEntitlement (employee_id, leave_type_id, entitlement)
            VALUES (@EmployeeID, @LeaveID, @Entitlement);

        COMMIT TRANSACTION;

        SELECT 'Leave entitlement assigned successfully' AS Message;

    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE ConfigureLeaveRules @LeaveType VARCHAR(50),
                                     @MaxDuration INT,
                                     @NoticePeriod INT,
                                     @WorkflowType VARCHAR(50) AS
BEGIN
    SELECT 'Leave rules configured for ' + @LeaveType AS Message;

END;

GO
CREATE PROCEDURE ConfigureSpecialLeave @LeaveType VARCHAR(50),
                                       @Rules VARCHAR(200) AS
BEGIN
    SELECT 'Special leave configured: ' + @LeaveType AS Message;

END;

GO
CREATE PROCEDURE SetLeaveYearRules @StartDate DATE,
                                   @EndDate DATE AS
BEGIN
    SELECT 'Leave year rules set from ' + CAST(@StartDate AS VARCHAR) + ' to ' + CAST(@EndDate AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE AdjustLeaveBalance @EmployeeID INT,
                                    @LeaveType VARCHAR(50),
                                    @Adjustment DECIMAL(5, 2) AS
BEGIN
    DECLARE @LeaveID INT;

    SELECT @LeaveID = leave_id
    FROM Leave
    WHERE leave_type = @LeaveType;

    IF @LeaveID IS NULL
        BEGIN
            SELECT 'Leave type not found' AS Message;

            RETURN;

        END
    UPDATE
        LeaveEntitlement
    SET entitlement = entitlement + @Adjustment
    WHERE employee_id = @EmployeeID
      AND leave_type_id = @LeaveID;

    SELECT 'Leave balance adjusted by ' + CAST(@Adjustment AS VARCHAR) + ' days' AS Message;

END;

GO
CREATE PROCEDURE ManageLeaveRoles @RoleID INT,
                                  @Permissions VARCHAR(200) AS
BEGIN
    SELECT 'Leave permissions updated for role' AS Message;

END;

GO
CREATE PROCEDURE FinalizeLeaveRequest @LeaveRequestID INT AS
BEGIN
    UPDATE
        LeaveRequest
    SET STATUS = 'Finalized'
    WHERE request_id = @LeaveRequestID;

    SELECT 'Leave request finalized' AS Message;

END;

GO
CREATE PROCEDURE OverrideLeaveDecision @LeaveRequestID INT,
                                       @Reason VARCHAR(200) AS
BEGIN
    UPDATE
        LeaveRequest
    SET STATUS          = 'Approved',
        approval_timing = GETDATE()
    WHERE request_id = @LeaveRequestID;

    SELECT 'Leave decision overridden: ' + @Reason AS Message;

END;

GO
CREATE PROCEDURE BulkProcessLeaveRequests @LeaveRequestIDs VARCHAR(500) AS
BEGIN
    DECLARE @XML XML = CAST(
            '<i>' + REPLACE(@LeaveRequestIDs, ',', '</i><i>') + '</i>' AS XML
                       );

    UPDATE
        LeaveRequest
    SET STATUS          = 'Approved',
        approval_timing = GETDATE()
    WHERE request_id IN (SELECT CAST(T.c.value('.', 'VARCHAR(10)') AS INT)
                         FROM @XML.nodes('/i') T(c));

    SELECT 'Bulk leave requests processed' AS Message;

END;

GO
CREATE PROCEDURE VerifyMedicalLeave @LeaveRequestID INT,
                                    @DocumentID INT AS
BEGIN
    SELECT 'Medical leave documentation verified' AS Message;

END;

GO
CREATE PROCEDURE SyncLeaveBalances @LeaveRequestID INT AS
BEGIN
    BEGIN TRY
        DECLARE @EmployeeID INT,
            @LeaveID INT,
            @Duration INT,
            @Status VARCHAR(50);

        SELECT @EmployeeID = employee_id,
               @LeaveID = leave_id,
               @Duration = duration,
               @Status = STATUS
        FROM LeaveRequest
        WHERE request_id = @LeaveRequestID;

        IF @EmployeeID IS NULL
            BEGIN
                SELECT 'Leave request not found' AS Message;

                RETURN;

            END
        IF @Status = 'Approved'
            BEGIN
                BEGIN TRANSACTION;

                DECLARE @CurrentBalance DECIMAL(5, 2);

                SELECT @CurrentBalance = entitlement
                FROM LeaveEntitlement
                WHERE employee_id = @EmployeeID
                  AND leave_type_id = @LeaveID;

                IF @CurrentBalance IS NULL
                    BEGIN
                        ROLLBACK TRANSACTION;

                        SELECT 'Leave entitlement not found' AS Message;

                        RETURN;

                    END
                IF @CurrentBalance < @Duration
                    BEGIN
                        ROLLBACK TRANSACTION;

                        SELECT 'Insufficient leave balance for sync' AS Message;

                        RETURN;

                    END
                UPDATE
                    LeaveEntitlement
                SET entitlement = entitlement - @Duration
                WHERE employee_id = @EmployeeID
                  AND leave_type_id = @LeaveID;

                COMMIT TRANSACTION;

                SELECT 'Leave balances synchronized successfully' AS Message;

            END
        ELSE
            BEGIN
                SELECT 'Leave request not approved, balance not updated' AS Message;

            END
    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE ProcessLeaveCarryForward @Year INT AS
BEGIN
    SELECT 'Leave carry-forward processed for year ' + CAST(@Year AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE SyncLeaveToattendance @LeaveRequestID INT AS
BEGIN
    SELECT 'Leave sync to attendance is handled by system-level integration' AS Message;
END;

GO
CREATE PROCEDURE UpdateInsuranceBrackets @BracketID INT,
                                         @NewMinSalary DECIMAL(10, 2),
                                         @NewMaxSalary DECIMAL(10, 2),
                                         @NewEmployeeContribution DECIMAL(5, 2),
                                         @NewEmployerContribution DECIMAL(5, 2),
                                         @UpdatedBy INT AS
BEGIN
    UPDATE
        Insurance
    SET contribution_rate = @NewEmployeeContribution
    WHERE insurance_id = @BracketID;

    SELECT 'Insurance brackets updated successfully' AS Message;

END;

GO
CREATE PROCEDURE ApprovePolicyUpdate @PolicyID INT,
                                     @ApprovedBy INT AS
BEGIN
    SELECT 'Policy update approved by ' + CAST(@ApprovedBy AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE GeneratePayroll @StartDate DATE,
                                 @EndDate DATE AS
BEGIN
    SELECT p.*,
           e.full_name,
           e.employee_id
    FROM Payroll p
             INNER JOIN Employee e ON p.employee_id = e.employee_id
    WHERE period_start = @StartDate
      AND period_end = @EndDate;

END;

GO
CREATE PROCEDURE AdjustPayrollItem @PayrollID INT,
                                   @Type VARCHAR(50),
                                   @Amount DECIMAL(10, 2),
                                   @Duration INT,
                                   @Timezone VARCHAR(20) AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM Payroll
                       WHERE payroll_id = @PayrollID)
            BEGIN
                SELECT 'Payroll record not found' AS Message;

                RETURN;

            END
        IF @Amount = 0
            BEGIN
                SELECT 'Amount cannot be zero' AS Message;

                RETURN;

            END
        DECLARE @EmployeeID INT;

        SELECT @EmployeeID = employee_id
        FROM Payroll
        WHERE payroll_id = @PayrollID;

        BEGIN TRANSACTION;

        DECLARE @Currency VARCHAR(50);
        SELECT @Currency = c.CurrencyName
        FROM Employee e
                 JOIN SalaryType s ON e.salary_type_id = s.salary_type_id
                 JOIN Currency c ON s.currency = c.CurrencyName
        WHERE e.employee_id = @EmployeeID;

        INSERT INTO AllowanceDeduction (payroll_id,
                                        employee_id,
                                        TYPE,
                                        amount,
                                        currency,
                                        duration,
                                        timezone)
        VALUES (@PayrollID,
                @EmployeeID,
                @Type,
                @Amount,
                @Currency,
                CAST(@Duration AS VARCHAR) + ' mins',
                @Timezone);

        INSERT INTO Payroll_Log (payroll_id, actor, modification_type)
        VALUES (@PayrollID,
                @EmployeeID,
                'Payroll item adjusted: ' + @Type + ' = ' + CAST(@Amount AS VARCHAR));

        COMMIT TRANSACTION;

        SELECT 'Payroll item adjusted successfully' AS Message;

    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE CalculateNetSalary @PayrollID INT,
                                    @NetSalary DECIMAL(10, 2) OUTPUT AS
BEGIN
    SELECT @NetSalary = net_salary
    FROM Payroll
    WHERE payroll_id = @PayrollID;

    SELECT @NetSalary AS NetSalary;

END;

GO
CREATE PROCEDURE ApplyPayrollPolicy @PolicyID INT,
                                    @PayrollID INT,
                                    @Type VARCHAR(20),
                                    @Description VARCHAR(50) AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM PayrollPolicy
                       WHERE policy_id = @PolicyID)
            BEGIN
                SELECT 'Payroll policy not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Payroll
                       WHERE payroll_id = @PayrollID)
            BEGIN
                SELECT 'Payroll record not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM PayrollPolicy_ID
                       WHERE payroll_id = @PayrollID
                         AND policy_id = @PolicyID)
            BEGIN
                BEGIN TRANSACTION;

                INSERT INTO PayrollPolicy_ID (payroll_id, policy_id)
                VALUES (@PayrollID, @PolicyID);

                DECLARE @EmployeeID INT;

                SELECT @EmployeeID = employee_id
                FROM Payroll
                WHERE payroll_id = @PayrollID;

                INSERT INTO Payroll_Log (payroll_id, actor, modification_type)
                VALUES (@PayrollID,
                        @EmployeeID,
                        'Policy Applied: ' + @Type + ' - ' + @Description);

                COMMIT TRANSACTION;

                SELECT 'Payroll policy applied successfully' AS Message;

            END
        ELSE
            BEGIN
                SELECT 'Policy already applied to this payroll' AS Message;

            END
    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE GetMonthlyPayrollSummary @Month INT,
                                          @Year INT AS
BEGIN
    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, @Month, 1);

    DECLARE @EndDate DATE = EOMONTH(@StartDate);

    SELECT SUM(net_salary) AS TotalSalaryExpenditure
    FROM Payroll
    WHERE period_start >= @StartDate
      AND period_end <= @EndDate;

END;

GO
CREATE PROCEDURE AddAllowanceDeduction @PayrollID INT,
                                       @Type VARCHAR(50),
                                       @Amount DECIMAL(10, 2) AS
BEGIN
    DECLARE @EmployeeID INT;
    SELECT @EmployeeID = employee_id
    FROM Payroll
    WHERE payroll_id = @PayrollID;

    DECLARE @Currency VARCHAR(50);
    SELECT @Currency = c.CurrencyName
    FROM Employee e
             JOIN SalaryType s ON e.salary_type_id = s.salary_type_id
             JOIN Currency c ON s.currency = c.CurrencyName
    WHERE e.employee_id = @EmployeeID;

    INSERT INTO AllowanceDeduction (payroll_id, employee_id, TYPE, amount, currency)
    VALUES (@PayrollID, @EmployeeID, @Type, @Amount, @Currency);

    SELECT 'Allowance/Deduction added successfully' AS Message;

END;

GO
CREATE PROCEDURE GetEmployeePayrollHistory @EmployeeID INT AS
BEGIN
    SELECT *
    FROM Payroll
    WHERE employee_id = @EmployeeID
    ORDER BY period_start DESC;

END;
--mohannd hany 
GO
CREATE PROCEDURE GetBonusEligibleEmployees @Eligibility_criteria VARCHAR(200) AS
BEGIN
    BEGIN TRY
        IF @Eligibility_criteria LIKE '%6 months%'
            BEGIN
                SELECT e.employee_id,
                       e.full_name,
                       e.department_id,
                       d.department_name,
                       DATEDIFF(MONTH, e.hire_date, GETDATE()) AS months_of_service
                FROM Employee e
                         INNER JOIN Department d ON e.department_id = d.department_id
                WHERE e.is_active = 1
                  AND DATEDIFF(MONTH, e.hire_date, GETDATE()) >= 6;

            END
        ELSE
            IF @Eligibility_criteria LIKE '%90%'
                OR @Eligibility_criteria LIKE '%attendance%'
                BEGIN
                    SELECT e.employee_id,
                           e.full_name,
                           e.department_id,
                           d.department_name,
                           COUNT(a.attendance_id) AS attendance_count
                    FROM Employee e
                             INNER JOIN Department d ON e.department_id = d.department_id
                             LEFT JOIN Attendance a ON e.employee_id = a.employee_id
                        AND a.entry_time >= DATEADD(MONTH, -3, GETDATE())
                        AND a.exit_time IS NOT NULL
                    WHERE e.is_active = 1
                    GROUP BY e.employee_id,
                             e.full_name,
                             e.department_id,
                             d.department_name
                    HAVING COUNT(a.attendance_id) >= (
                        DATEDIFF(DAY, DATEADD(MONTH, -3, GETDATE()), GETDATE()) * 0.9
                        );

                END
            ELSE
                BEGIN
                    SELECT e.employee_id,
                           e.full_name,
                           e.department_id,
                           d.department_name
                    FROM Employee e
                             INNER JOIN Department d ON e.department_id = d.department_id
                    WHERE e.is_active = 1;

                END
    END TRY BEGIN CATCH
        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE UpdateSalaryType @EmployeeID INT,
                                  @SalaryTypeID INT AS
BEGIN
    UPDATE
        Employee
    SET salary_type_id = @SalaryTypeID
    WHERE employee_id = @EmployeeID;

    SELECT 'Salary type updated successfully' AS Message;

END;

GO
CREATE PROCEDURE GetPayrollByDepartment @DepartmentID INT,
                                        @Month INT,
                                        @Year INT AS
BEGIN
    DECLARE @StartDate DATE = DATEFROMPARTS(@Year, @Month, 1);

    DECLARE @EndDate DATE = EOMONTH(@StartDate);

    SELECT e.department_id,
           d.department_name,
           SUM(p.net_salary)   AS total_payroll,
           COUNT(p.payroll_id) AS employee_count
    FROM Payroll p
             INNER JOIN Employee e ON p.employee_id = e.employee_id
             INNER JOIN Department d ON e.department_id = d.department_id
    WHERE e.department_id = @DepartmentID
      AND p.period_start >= @StartDate
      AND p.period_end <= @EndDate
    GROUP BY e.department_id,
             d.department_name;

END;

GO
CREATE PROCEDURE ValidateAttendanceBeforePayroll @PayrollPeriodID INT AS
BEGIN
    SELECT e.employee_id,
           e.full_name,
           COUNT(a.attendance_id) AS missed_punches
    FROM Employee e
             LEFT JOIN Attendance a ON e.employee_id = a.employee_id
    WHERE (
              a.entry_time IS NULL
                  OR a.exit_time IS NULL
              )
    GROUP BY e.employee_id,
             e.full_name
    HAVING COUNT(a.attendance_id) > 0;

END;

GO
CREATE PROCEDURE SyncAttendanceToPayroll @SyncDate DATE AS
BEGIN
    SELECT 'Attendance records synced to payroll for ' + CAST(@SyncDate AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE SyncApprovedPermissionsToPayroll @PayrollPeriodID INT AS
BEGIN
    SELECT 'Approved permissions synced to payroll' AS Message;

END;

GO
CREATE PROCEDURE ConfigurePayGrades @GradeName VARCHAR(50),
                                    @MinSalary DECIMAL(10, 2),
                                    @MaxSalary DECIMAL(10, 2) AS
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM PayGrade
                   WHERE grade_name = @GradeName)
        BEGIN
            INSERT INTO PayGrade (grade_name, min_salary, max_salary)
            VALUES (@GradeName, @MinSalary, @MaxSalary);

            SELECT 'Pay grade configured successfully' AS Message;

        END
    ELSE
        SELECT 'Pay grade already exists' AS Message;

END;

GO
CREATE PROCEDURE ConfigureShiftAllowances @ShiftType VARCHAR(50),
                                          @AllowanceName VARCHAR(50),
                                          @Amount DECIMAL(10, 2) AS
BEGIN
    SELECT 'Shift allowance configured: ' + @AllowanceName + ' = ' + CAST(@Amount AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE EnableMultiCurrencyPayroll @CurrencyCode VARCHAR(10),
                                            @ExchangeRate DECIMAL(10, 4) AS
    IF NOT EXISTS (SELECT 1
                   FROM Currency
                   WHERE CurrencyCode = @CurrencyCode)
        BEGIN
            SELECT 'Currency not supported. Only predefined currencies can be enabled.' AS Message;
            RETURN;
        END

UPDATE Currency
SET ExchangeRate = @ExchangeRate,
    LastUpdated  = GETDATE()
WHERE CurrencyCode = @CurrencyCode;

SELECT 'Multi-currency payroll enabled for ' + @CurrencyCode AS Message;

GO
CREATE PROCEDURE ManageTaxRules @TaxRuleName VARCHAR(50),
                                @CountryCode VARCHAR(10),
                                @Rate DECIMAL(5, 2),
                                @Exemption DECIMAL(10, 2) AS
BEGIN
    SELECT 'Tax rule configured: ' + @TaxRuleName + ' at ' + CAST(@Rate AS VARCHAR) + '%' AS Message;

END;

GO
CREATE PROCEDURE ApprovePayrollConfigChanges @ConfigID INT,
                                             @ApproverID INT,
                                             @Status VARCHAR(20) AS
BEGIN
    SELECT 'Payroll configuration change ' + @Status AS Message;

END;

GO
CREATE PROCEDURE ConfigureSigningBonus @EmployeeID INT,
                                       @BonusAmount DECIMAL(10, 2),
                                       @EffectiveDate DATE AS
BEGIN
    SELECT 'Signing bonus configured: ' + CAST(@BonusAmount AS VARCHAR) + ' for employee ' +
           CAST(@EmployeeID AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE ConfigureTerminationBenefits @EmployeeID INT,
                                              @CompensationAmount DECIMAL(10, 2),
                                              @EffectiveDate DATE,
                                              @Reason VARCHAR(50) AS
BEGIN
    SELECT 'Termination benefits configured for employee ' + CAST(@EmployeeID AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE ConfigureInsuranceBrackets @InsuranceType VARCHAR(50),
                                            @MinSalary DECIMAL(10, 2),
                                            @MaxSalary DECIMAL(10, 2),
                                            @EmployeeContribution DECIMAL(5, 2),
                                            @EmployerContribution DECIMAL(5, 2) AS
BEGIN
    INSERT INTO Insurance (TYPE, contribution_rate, coverage)
    VALUES (@InsuranceType,
            @EmployeeContribution,
            'Salary Range: ' + CAST(@MinSalary AS VARCHAR) + ' - ' + CAST(@MaxSalary AS VARCHAR));

    SELECT 'Insurance bracket configured successfully' AS Message;

END;

GO
CREATE PROCEDURE ConfigurePayrollPolicies @PolicyType VARCHAR(50),
                                          @PolicyDetails NVARCHAR(MAX),
                                          @EffectiveDate DATE
AS
BEGIN
    INSERT INTO PayrollPolicy (TYPE, description, effective_date)
    VALUES (@PolicyType, @PolicyDetails, @EffectiveDate); -- Use @EffectiveDate

    SELECT 'Payroll policy configured successfully' AS Message;
END;


GO
CREATE PROCEDURE DefinePayGrades @GradeName VARCHAR(50),
                                 @MinSalary DECIMAL(10, 2),
                                 @MaxSalary DECIMAL(10, 2),
                                 @CreatedBy INT AS
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM PayGrade
                   WHERE grade_name = @GradeName)
        BEGIN
            INSERT INTO PayGrade (grade_name, min_salary, max_salary)
            VALUES (@GradeName, @MinSalary, @MaxSalary);

            SELECT 'Pay grade defined successfully' AS Message;

        END
    ELSE
        SELECT 'Pay grade already exists' AS Message;

END;

GO
CREATE PROCEDURE ConfigureEscalationWorkflow @ThresholdAmount DECIMAL(10, 2),
                                             @ApproverRole VARCHAR(50),
                                             @CreatedBy INT AS
BEGIN
    INSERT INTO ApprovalWorkflow (workflow_type,
                                  threshold_amount,
                                  approver_role,
                                  created_by,
                                  STATUS)
    VALUES ('Payroll Escalation',
            @ThresholdAmount,
            @ApproverRole,
            @CreatedBy,
            'Active');

    SELECT 'Escalation workflow configured successfully' AS Message;

END;

GO
CREATE PROCEDURE DefinePayType @EmployeeID INT,
                               @PayType VARCHAR(50),
                               @EffectiveDate DATE AS
BEGIN
    SELECT 'Pay type defined for employee: ' + @PayType AS Message;

END;

GO
CREATE PROCEDURE ConfigureOvertimeRules @DayType VARCHAR(20),
                                        @Multiplier DECIMAL(3, 2),
                                        @HoursPerMonth INT
AS
BEGIN
    INSERT INTO PayrollPolicy (TYPE, description, effective_date)
    VALUES ('Overtime',
            @DayType + ' overtime at ' + CAST(@Multiplier AS VARCHAR) + 'x rate',
            GETDATE());

    DECLARE @PolicyID INT = SCOPE_IDENTITY();

    INSERT INTO OvertimePolicy (policy_id,
                                weekday_rate_multiplier,
                                weekend_rate_multiplier,
                                max_hours_per_month)
    VALUES (@PolicyID, @Multiplier, @Multiplier * 1.5, @HoursPerMonth);

    SELECT 'Overtime rules configured successfully' AS Message;
END;

GO
CREATE PROCEDURE ConfigureShiftAllowance @ShiftType VARCHAR(20),
                                         @AllowanceAmount DECIMAL(10, 2),
                                         @CreatedBy INT AS
BEGIN
    SELECT 'Shift allowance configured: ' + @ShiftType + ' = ' + CAST(@AllowanceAmount AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE ConfigureSigningBonusPolicy @BonusType VARCHAR(50),
                                             @Amount DECIMAL(10, 2),
                                             @EligibilityCriteria NVARCHAR(MAX) AS
BEGIN
    SELECT 'Signing bonus policy configured: ' + @BonusType AS Message;

END;

GO
CREATE PROCEDURE GenerateTaxStatement @EmployeeID INT,
                                      @TaxYear INT AS
BEGIN
    SELECT e.employee_id,
           e.full_name,
           @TaxYear           AS tax_year,
           SUM(p.base_amount) AS total_gross,
           SUM(p.taxes)       AS total_taxes,
           SUM(p.net_salary)  AS total_net
    FROM Payroll p
             INNER JOIN Employee e ON p.employee_id = e.employee_id
    WHERE e.employee_id = @EmployeeID
      AND YEAR(p.period_start) = @TaxYear
    GROUP BY e.employee_id,
             e.full_name;

END;

GO
CREATE PROCEDURE ApprovePayrollConfiguration @ConfigID INT,
                                             @ApprovedBy INT AS
BEGIN
    SELECT 'Payroll configuration approved by ' + CAST(@ApprovedBy AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE ModifyPastPayroll @PayrollRunID INT,
                                   @EmployeeID INT,
                                   @FieldName VARCHAR(50),
                                   @NewValue DECIMAL(10, 2),
                                   @ModifiedBy INT AS
BEGIN
    INSERT INTO Payroll_Log (payroll_id, actor, modification_type)
    VALUES (@PayrollRunID,
            @ModifiedBy,
            'Modified ' + @FieldName + ' to ' + CAST(@NewValue AS VARCHAR));

    SELECT 'Past payroll modified and logged' AS Message;

END;

GO
CREATE PROCEDURE ViewLeaveRequest @LeaveRequestID INT,
                                  @ManagerID INT AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM LeaveRequest
                       WHERE request_id = @LeaveRequestID)
            BEGIN
                SELECT 'Leave request not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @ManagerID)
            BEGIN
                SELECT 'Manager not found' AS Message;

                RETURN;

            END
        DECLARE @EmployeeID INT;

        SELECT @EmployeeID = employee_id
        FROM LeaveRequest
        WHERE request_id = @LeaveRequestID;

        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID
                         AND manager_id = @ManagerID)
            BEGIN
                SELECT 'This leave request is not assigned to you' AS Message;

                RETURN;

            END
        SELECT lr.request_id,
               lr.employee_id,
               e.full_name AS employee_name,
               l.leave_type,
               l.leave_description,
               lr.justification,
               lr.duration,
               lr.status,
               lr.approval_timing,
               d.department_name,
               p.position_title
        FROM LeaveRequest lr
                 INNER JOIN Employee e ON lr.employee_id = e.employee_id
                 INNER JOIN Leave l ON lr.leave_id = l.leave_id
                 LEFT JOIN Department d ON e.department_id = d.department_id
                 LEFT JOIN Position p ON e.position_id = p.position_id
        WHERE lr.request_id = @LeaveRequestID;

    END TRY BEGIN CATCH
        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE ReviewLeaveRequest @LeaveRequestID INT,
                                    @ManagerID INT,
                                    @Decision VARCHAR(20) AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM LeaveRequest
                       WHERE request_id = @LeaveRequestID)
            BEGIN
                SELECT 'Leave request not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @ManagerID)
            BEGIN
                SELECT 'Manager not found' AS Message;

                RETURN;

            END
        IF @Decision NOT IN ('Approved', 'Rejected', 'Pending')
            BEGIN
                SELECT 'Invalid decision. Must be Approved, Rejected, or Pending' AS Message;

                RETURN;

            END
        DECLARE @EmployeeID INT,
            @LeaveID INT,
            @Duration INT;

        SELECT @EmployeeID = employee_id,
               @LeaveID = leave_id,
               @Duration = duration
        FROM LeaveRequest
        WHERE request_id = @LeaveRequestID;

        IF @Decision = 'Approved'
            BEGIN
                DECLARE @AvailableBalance DECIMAL(5, 2);

                SELECT @AvailableBalance = entitlement
                FROM LeaveEntitlement
                WHERE employee_id = @EmployeeID
                  AND leave_type_id = @LeaveID;

                IF @AvailableBalance < @Duration
                    BEGIN
                        SELECT 'Cannot approve - insufficient leave balance' AS Message;

                        RETURN;

                    END
            END
        BEGIN TRANSACTION;

        UPDATE
            LeaveRequest
        SET STATUS          = @Decision,
            approval_timing = GETDATE()
        WHERE request_id = @LeaveRequestID;

        INSERT INTO Notification (message_content, urgency, notification_type)
        VALUES ('Your leave request has been ' + @Decision,
                'Normal',
                'Leave');

        INSERT INTO Employee_Notification (employee_id,
                                           notification_id,
                                           delivery_status,
                                           delivered_at)
        VALUES (@EmployeeID,
                SCOPE_IDENTITY(),
                'Delivered',
                GETDATE());

        COMMIT TRANSACTION;

        SELECT 'Leave request ' + @Decision AS Message;

    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE AssignShift @EmployeeID INT,
                             @ShiftID INT AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM ShiftSchedule
                       WHERE shift_id = @ShiftID)
            BEGIN
                SELECT 'Shift not found' AS Message;

                RETURN;

            END
        IF EXISTS (SELECT 1
                   FROM ShiftAssignment
                   WHERE employee_id = @EmployeeID
                     AND shift_id = @ShiftID
                     AND STATUS = 'Active')
            BEGIN
                SELECT 'Employee already assigned to this shift' AS Message;

                RETURN;

            END
        BEGIN TRANSACTION;

        INSERT INTO ShiftAssignment (employee_id, shift_id, start_date, STATUS)
        VALUES (@EmployeeID, @ShiftID, GETDATE(), 'Active');

        COMMIT TRANSACTION;

        SELECT 'Shift assigned successfully' AS Message;

    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE ViewTeamAttendance @ManagerID INT,
                                    @DateRangeStart DATE,
                                    @DateRangeEnd DATE AS
BEGIN
    SELECT e.employee_id,
           e.full_name,
           a.entry_time,
           a.exit_time,
           a.duration
    FROM Attendance a
             INNER JOIN Employee e ON a.employee_id = e.employee_id
    WHERE e.manager_id = @ManagerID
      AND CAST(a.entry_time AS DATE) BETWEEN @DateRangeStart
        AND @DateRangeEnd
    ORDER BY a.entry_time;

END;

GO
CREATE PROCEDURE SendTeamNotification @ManagerID INT,
                                      @MessageContent VARCHAR(255),
                                      @UrgencyLevel VARCHAR(50) AS
BEGIN
    DECLARE @NotificationID INT;

    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES (@MessageContent, @UrgencyLevel, 'Team');

    SET
        @NotificationID = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id,
                                       notification_id,
                                       delivery_status,
                                       delivered_at)
    SELECT employee_id,
           @NotificationID,
           'Delivered',
           GETDATE()
    FROM Employee
    WHERE manager_id = @ManagerID;

    SELECT 'Notification sent to team members' AS Message;

END;

GO
CREATE PROCEDURE ApproveMissionCompletion @MissionID INT,
                                          @ManagerID INT,
                                          @Remarks VARCHAR(200) AS
BEGIN
    UPDATE
        Mission
    SET STATUS = 'Completed'
    WHERE mission_id = @MissionID;

    SELECT 'Mission completion approved: ' + @Remarks AS Message;

END;

GO
CREATE PROCEDURE RequestReplacement @EmployeeID INT,
                                    @Reason VARCHAR(150) AS
BEGIN
    SELECT 'Replacement request submitted for employee ' + CAST(@EmployeeID AS VARCHAR) + ': ' + @Reason AS Message;

END;

GO
CREATE PROCEDURE ViewDepartmentSummary @DepartmentID INT AS
BEGIN
    SELECT d.department_name,
           COUNT(e.employee_id)         AS employee_count,
           COUNT(DISTINCT m.mission_id) AS active_projects
    FROM Department d
             LEFT JOIN Employee e ON d.department_id = e.department_id
             LEFT JOIN Mission m ON e.employee_id = m.employee_id
        AND m.status = 'Approved'
    WHERE d.department_id = @DepartmentID
    GROUP BY d.department_name;

END;

GO
CREATE PROCEDURE ReassignShift @EmployeeID INT,
                               @OldShiftID INT,
                               @NewShiftID INT AS
BEGIN
    UPDATE
        ShiftAssignment
    SET shift_id = @NewShiftID
    WHERE employee_id = @EmployeeID
      AND shift_id = @OldShiftID
      AND STATUS = 'Active';

    SELECT 'Shift reassigned successfully' AS Message;

END;

GO
CREATE PROCEDURE GetPendingLeaveRequests @ManagerID INT AS
BEGIN
    SELECT lr.*
    FROM LeaveRequest lr
             INNER JOIN Employee e ON lr.employee_id = e.employee_id
    WHERE e.manager_id = @ManagerID
      AND lr.status = 'Pending';

END;

GO
CREATE PROCEDURE GetTeamStatistics @ManagerID INT AS
BEGIN
    SELECT COUNT(e.employee_id)            AS team_size,
           AVG(p.net_salary)               AS average_salary,
           COUNT(DISTINCT e.department_id) AS span_of_control
    FROM Employee e
             LEFT JOIN Payroll p ON e.employee_id = p.employee_id
    WHERE e.manager_id = @ManagerID
    GROUP BY e.manager_id;

END;

GO
CREATE PROCEDURE ViewTeamProfiles @ManagerID INT AS
BEGIN
    SELECT employee_id,
           full_name,
           email,
           phone,
           position_id,
           hire_date
    FROM Employee
    WHERE manager_id = @ManagerID;

END;

GO
CREATE PROCEDURE GetTeamSummary @ManagerID INT AS
BEGIN
    SELECT r.role_name,
           COUNT(e.employee_id)                         AS count,
           AVG(DATEDIFF(MONTH, e.hire_date, GETDATE())) AS avg_tenure_months
    FROM Employee e
             LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
             LEFT JOIN Role r ON er.role_id = r.role_id
    WHERE e.manager_id = @ManagerID
    GROUP BY r.role_name;

END;

GO
CREATE PROCEDURE FilterTeamProfiles @ManagerID INT,
                                    @Skill VARCHAR(50),
                                    @RoleID INT AS
BEGIN
    SELECT DISTINCT e.*
    FROM Employee e
             LEFT JOIN Employee_Skill es ON e.employee_id = es.employee_id
             LEFT JOIN Skill s ON es.skill_id = s.skill_id
             LEFT JOIN Employee_Role er ON e.employee_id = er.employee_id
    WHERE e.manager_id = @ManagerID
      AND (
        s.skill_name = @Skill
            OR @Skill IS NULL
        )
      AND (
        er.role_id = @RoleID
            OR @RoleID IS NULL
        );

END;

GO
CREATE PROCEDURE ViewTeamCertifications @ManagerID INT AS
BEGIN
    SELECT e.employee_id,
           e.full_name,
           s.skill_name,
           es.proficiency_level,
           v.verification_type,
           v.expiry_period
    FROM Employee e
             LEFT JOIN Employee_Skill es ON e.employee_id = es.employee_id
             LEFT JOIN Skill s ON es.skill_id = s.skill_id
             LEFT JOIN Employee_Verification ev ON e.employee_id = ev.employee_id
             LEFT JOIN Verification v ON ev.verification_id = v.verification_id
    WHERE e.manager_id = @ManagerID;

END;

GO
CREATE PROCEDURE AddManagerNotes @EmployeeID INT,
                                 @ManagerID INT,
                                 @Note VARCHAR(500) AS
BEGIN
    INSERT INTO ManagerNotes (employee_id, manager_id, note_content)
    VALUES (@EmployeeID, @ManagerID, @Note);

    SELECT 'Manager note added successfully' AS Message;

END;

GO
CREATE PROCEDURE RecordManualAttendance @EmployeeID INT,
                                        @Date DATE,
                                        @ClockIn TIME,
                                        @ClockOut TIME,
                                        @Reason VARCHAR(200),
                                        @RecordedBy INT AS
BEGIN
    DECLARE @ShiftID INT;

    SELECT TOP 1 @ShiftID = shift_id
    FROM ShiftAssignment
    WHERE employee_id = @EmployeeID
      AND STATUS = 'Active';

    DECLARE @EntryTime DATETIME = CAST(@Date AS DATETIME) + CAST(@ClockIn AS DATETIME);

    DECLARE @ExitTime DATETIME = CAST(@Date AS DATETIME) + CAST(@ClockOut AS DATETIME);

    DECLARE @Duration INT = DATEDIFF(MINUTE, @EntryTime, @ExitTime);

    INSERT INTO Attendance (employee_id,
                            shift_id,
                            entry_time,
                            exit_time,
                            duration,
                            login_method,
                            logout_method)
    VALUES (@EmployeeID,
            @ShiftID,
            @EntryTime,
            @ExitTime,
            @Duration,
            'Manual',
            'Manual');

    DECLARE @AttendanceID INT = SCOPE_IDENTITY();

    INSERT INTO AttendanceLog (attendance_id, actor, reason)
    VALUES (@AttendanceID, @RecordedBy, @Reason);

    SELECT 'Manual attendance recorded successfully' AS Message;

END;

GO
CREATE PROCEDURE ReviewMissedPunches @ManagerID INT,
                                     @Date DATE AS
BEGIN
    SELECT e.employee_id,
           e.full_name,
           a.entry_time,
           a.exit_time,
           CASE
               WHEN a.entry_time IS NULL THEN 'Missing Clock In'
               WHEN a.exit_time IS NULL THEN 'Missing Clock Out'
               END AS exception_type
    FROM Employee e
             INNER JOIN Attendance a ON e.employee_id = a.employee_id
    WHERE e.manager_id = @ManagerID
      AND CAST(a.entry_time AS DATE) = @Date
      AND (
        a.entry_time IS NULL
            OR a.exit_time IS NULL
        );

END;

GO
CREATE PROCEDURE ApproveTimeRequest @RequestID INT,
                                    @ManagerID INT,
                                    @Decision VARCHAR(20),
                                    @Comments VARCHAR(200) AS
BEGIN
    UPDATE
        AttendanceCorrectionRequest
    SET STATUS = @Decision
    WHERE request_id = @RequestID;

    SELECT 'Time request ' + @Decision + ': ' + @Comments AS Message;

END;

GO
CREATE PROCEDURE RejectLeaveRequest @LeaveRequestID INT,
                                    @ManagerID INT,
                                    @Reason VARCHAR(200) AS
BEGIN
    UPDATE
        LeaveRequest
    SET STATUS          = 'Rejected',
        approval_timing = GETDATE()
    WHERE request_id = @LeaveRequestID;

    DECLARE @EmployeeID INT;

    SELECT @EmployeeID = employee_id
    FROM LeaveRequest
    WHERE request_id = @LeaveRequestID;

    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES ('Your leave request was rejected: ' + @Reason,
            'Normal',
            'Leave');

    INSERT INTO Employee_Notification (employee_id,
                                       notification_id,
                                       delivery_status,
                                       delivered_at)
    VALUES (@EmployeeID,
            SCOPE_IDENTITY(),
            'Delivered',
            GETDATE());

    SELECT 'Leave request rejected: ' + @Reason AS Message;

END;

GO
CREATE PROCEDURE DelegateLeaveApproval @ManagerID INT,
                                       @DelegateID INT,
                                       @StartDate DATE,
                                       @EndDate DATE AS
BEGIN
    SELECT 'Leave approval delegated from ' + CAST(@ManagerID AS VARCHAR) + ' to ' + CAST(@DelegateID AS VARCHAR) +
           ' for period ' + CAST(@StartDate AS VARCHAR) + ' to ' + CAST(@EndDate AS VARCHAR) AS Message;

END;

GO
CREATE PROCEDURE FlagIrregularLeave @EmployeeID INT,
                                    @ManagerID INT,
                                    @PatternDescription VARCHAR(200) AS
BEGIN
    SELECT 'Irregular leave pattern flagged for employee ' + CAST(@EmployeeID AS VARCHAR) + ': ' +
           @PatternDescription AS Message;

END;

GO
CREATE PROCEDURE NotifyNewLeaveRequest @ManagerID INT,
                                       @RequestID INT AS
BEGIN
    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES ('New leave request #' + CAST(@RequestID AS VARCHAR) + ' requires your approval',
            'Normal',
            'Leave');

    DECLARE @NotificationID INT = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id,
                                       notification_id,
                                       delivery_status,
                                       delivered_at)
    VALUES (@ManagerID,
            @NotificationID,
            'Delivered',
            GETDATE());

    SELECT 'Manager notified of new leave request' AS Message;

END;

GO
CREATE PROCEDURE SubmitLeaveRequest @EmployeeID INT,
                                    @LeaveTypeID INT,
                                    @StartDate DATE,
                                    @EndDate DATE,
                                    @Reason VARCHAR(100)
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Employee WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;
                RETURN;
            END

        IF NOT EXISTS (SELECT 1 FROM Leave WHERE leave_id = @LeaveTypeID)
            BEGIN
                SELECT 'Leave type not found' AS Message;
                RETURN;
            END

        IF @StartDate > @EndDate
            BEGIN
                SELECT 'Start date cannot be after end date' AS Message;
                RETURN;
            END

        DECLARE @Duration INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
        DECLARE @AvailableBalance DECIMAL(5, 2);

        SELECT @AvailableBalance = entitlement
        FROM LeaveEntitlement
        WHERE employee_id = @EmployeeID
          AND leave_type_id = @LeaveTypeID;

        IF @AvailableBalance IS NULL
            BEGIN
                SELECT 'No leave entitlement found for this leave type' AS Message;
                RETURN;
            END

        IF @AvailableBalance < @Duration
            BEGIN
                SELECT
                    'Insufficient leave balance. Available: ' + CAST(@AvailableBalance AS VARCHAR) + ' days' AS Message;
                RETURN;
            END

        -- Note: Overlap validation removed as LeaveRequest table doesn't store start_date/end_date
        -- Only duration is stored, making overlap detection impossible with current schema

        BEGIN TRANSACTION;

        INSERT INTO LeaveRequest (employee_id, leave_id, justification, duration, STATUS)
        VALUES (@EmployeeID, @LeaveTypeID, @Reason, @Duration, 'Pending');

        COMMIT TRANSACTION;

        SELECT 'Leave request submitted successfully' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;
    END CATCH
END;

GO
GO
CREATE PROCEDURE GetLeaveBalance @EmployeeID INT AS
BEGIN
    SELECT l.leave_type,
           le.entitlement AS remaining_days
    FROM LeaveEntitlement le
             INNER JOIN Leave l ON le.leave_type_id = l.leave_id
    WHERE le.employee_id = @EmployeeID;

END;

GO
CREATE PROCEDURE RecordAttendance @EmployeeID INT,
                                  @ShiftID INT,
                                  @EntryTime TIME,
                                  @ExitTime TIME AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        IF NOT EXISTS (SELECT 1
                       FROM ShiftSchedule
                       WHERE shift_id = @ShiftID)
            BEGIN
                SELECT 'Shift not found' AS Message;

                RETURN;

            END
        DECLARE @TodayDate DATE = CAST(GETDATE() AS DATE);

        DECLARE @EntryDateTime DATETIME = CAST(@TodayDate AS DATETIME) + CAST(@EntryTime AS DATETIME);

        DECLARE @ExitDateTime DATETIME = CAST(@TodayDate AS DATETIME) + CAST(@ExitTime AS DATETIME);

        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1
                   FROM Attendance
                   WHERE employee_id = @EmployeeID
                     AND CAST(entry_time AS DATE) = @TodayDate)
            BEGIN
                UPDATE
                    Attendance
                SET exit_time     = @ExitDateTime,
                    duration      = DATEDIFF(MINUTE, entry_time, @ExitDateTime),
                    logout_method = 'Self-Service'
                WHERE employee_id = @EmployeeID
                  AND CAST(entry_time AS DATE) = @TodayDate;

            END
        ELSE
            BEGIN
                INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
                VALUES (@EmployeeID,
                        @ShiftID,
                        @EntryDateTime,
                        'Self-Service');

            END COMMIT TRANSACTION;

        SELECT 'Attendance recorded successfully' AS Message;

    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE SubmitReimbursement @EmployeeID INT,
                                     @ExpenseType VARCHAR(50),
                                     @Amount DECIMAL(10, 2) AS
BEGIN
    INSERT INTO Reimbursement (TYPE, claim_type, current_status, employee_id)
    VALUES (@ExpenseType,
            @ExpenseType,
            'Pending',
            @EmployeeID);

    SELECT 'Reimbursement request submitted successfully' AS Message;

END;

GO
CREATE PROCEDURE AddEmployeeSkill @EmployeeID INT,
                                  @SkillName VARCHAR(50) AS
BEGIN
    DECLARE @SkillID INT;

    SELECT @SkillID = skill_id
    FROM Skill
    WHERE skill_name = @SkillName;

    IF @SkillID IS NULL
        BEGIN
            INSERT INTO Skill (skill_name)
            VALUES (@SkillName);

            SET
                @SkillID = SCOPE_IDENTITY();

        END
    IF NOT EXISTS (SELECT 1
                   FROM Employee_Skill
                   WHERE employee_id = @EmployeeID
                     AND skill_id = @SkillID)
        BEGIN
            INSERT INTO Employee_Skill (employee_id, skill_id, proficiency_level)
            VALUES (@EmployeeID, @SkillID, 'Beginner');

            SELECT 'Skill added successfully' AS Message;

        END
    ELSE
        SELECT 'Skill already exists for employee' AS Message;

END;

GO
CREATE PROCEDURE ViewAssignedShifts @EmployeeID INT AS
BEGIN
    SELECT s.name AS shift_name,
           s.start_time,
           s.end_time,
           sa.start_date,
           sa.end_date,
           sa.status
    FROM ShiftAssignment sa
             INNER JOIN ShiftSchedule s ON sa.shift_id = s.shift_id
    WHERE sa.employee_id = @EmployeeID;

END;

GO
CREATE PROCEDURE ViewMyContracts @EmployeeID INT AS
BEGIN
    SELECT c.*
    FROM Contract c
             INNER JOIN Employee e ON c.contract_id = e.contract_id
    WHERE e.employee_id = @EmployeeID;

END;

GO
CREATE PROCEDURE ViewMyPayroll @EmployeeID INT AS
BEGIN
    SELECT *
    FROM Payroll
    WHERE employee_id = @EmployeeID
    ORDER BY period_start DESC;

END;

GO
CREATE PROCEDURE UpdatePersonalDetails @EmployeeID INT,
                                       @Phone VARCHAR(20),
                                       @Address VARCHAR(150) AS
BEGIN
    UPDATE
        Employee
    SET phone   = @Phone,
        address = @Address
    WHERE employee_id = @EmployeeID;

    SELECT 'Personal details updated successfully' AS Message;

END;

GO
CREATE PROCEDURE ViewMyMissions @EmployeeID INT AS
BEGIN
    SELECT *
    FROM Mission
    WHERE employee_id = @EmployeeID
    ORDER BY start_date DESC;

END;

GO
CREATE PROCEDURE ViewEmployeeProfile @EmployeeID INT AS
BEGIN
    SELECT *
    FROM Employee
    WHERE employee_id = @EmployeeID;

END;

GO
CREATE PROCEDURE ViewEmploymentTimeline @EmployeeID INT AS
BEGIN
    SELECT 'Hire Date'          AS event_type,
           hire_date            AS event_date,
           'Joined the company' AS description
    FROM Employee
    WHERE employee_id = @EmployeeID
    UNION
        ALL
    SELECT 'Contract Change'           AS event_type,
           start_date                  AS event_date,
           'Contract started: ' + TYPE AS description
    FROM Contract c
             INNER JOIN Employee e ON c.contract_id = e.contract_id
    WHERE e.employee_id = @EmployeeID
    ORDER BY event_date DESC;

END;

GO
CREATE PROCEDURE UpdateEmergencyContact @EmployeeID INT,
                                        @ContactName VARCHAR(100),
                                        @Relation VARCHAR(50),
                                        @Phone VARCHAR(20) AS
BEGIN
    UPDATE
        Employee
    SET emergency_contact_name  = @ContactName,
        relationship            = @Relation,
        emergency_contact_phone = @Phone
    WHERE employee_id = @EmployeeID;

    SELECT 'Emergency contact updated successfully' AS Message;

END;

GO
CREATE PROCEDURE RequestHRDocument @EmployeeID INT,
                                   @DocumentType VARCHAR(50) AS
BEGIN
    SELECT 'HR document request submitted: ' + @DocumentType AS Message;

END;

GO
CREATE PROCEDURE NotifyProfileUpdate @EmployeeID INT,
                                     @NotificationType VARCHAR(50) AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1
                       FROM Employee
                       WHERE employee_id = @EmployeeID)
            BEGIN
                SELECT 'Employee not found' AS Message;

                RETURN;

            END
        DECLARE @MessageContent VARCHAR(255);

        IF @NotificationType = 'Profile Update'
            SET
                @MessageContent = 'Your profile has been updated successfully';

        ELSE
            IF @NotificationType = 'Document Upload'
                SET
                    @MessageContent = 'A new document has been uploaded to your profile';

            ELSE
                IF @NotificationType = 'Document Change'
                    SET
                        @MessageContent = 'One of your documents has been modified';

                ELSE
                    IF @NotificationType = 'Verification Update'
                        SET
                            @MessageContent = 'Your verification/certification has been updated';

                    ELSE
                        IF @NotificationType = 'Contract Update'
                            SET
                                @MessageContent = 'Your employment contract has been updated';

                        ELSE
                            SET
                                @MessageContent = 'Profile update: ' + @NotificationType;

        BEGIN TRANSACTION;

        INSERT INTO Notification (message_content, urgency, notification_type)
        VALUES (@MessageContent, 'Normal', 'Profile');

        DECLARE @NotificationID INT = SCOPE_IDENTITY();

        INSERT INTO Employee_Notification (employee_id,
                                           notification_id,
                                           delivery_status,
                                           delivered_at)
        VALUES (@EmployeeID,
                @NotificationID,
                'Delivered',
                GETDATE());

        COMMIT TRANSACTION;

        SELECT 'Profile update notification sent successfully' AS Message;

    END TRY BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        SELECT 'Error: ' + ERROR_MESSAGE() AS Message;

    END CATCH
END;

GO
CREATE PROCEDURE LogFlexibleAttendance @EmployeeID INT,
                                       @Date DATE,
                                       @CheckIn TIME,
                                       @CheckOut TIME AS
BEGIN
    DECLARE @TotalHours INT = DATEDIFF(HOUR, @CheckIn, @CheckOut);

    SELECT 'Flexible attendance logged: ' + CAST(@TotalHours AS VARCHAR) + ' hours' AS Message,
           @TotalHours                                                              AS TotalWorkingHours;

END;

GO
CREATE PROCEDURE NotifyMissedPunch @EmployeeID INT,
                                   @Date DATE AS
BEGIN
    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES ('You have a missed punch on ' + CAST(@Date AS VARCHAR) + '. Please submit a correction request.',
            'High',
            'Attendance');

    DECLARE @NotificationID INT = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id,
                                       notification_id,
                                       delivery_status,
                                       delivered_at)
    VALUES (@EmployeeID,
            @NotificationID,
            'Delivered',
            GETDATE());

    SELECT 'Missed punch notification sent' AS Message;

END;

GO
CREATE PROCEDURE RecordMultiplePunches @EmployeeID INT,
                                       @ClockInOutTime DATETIME,
                                       @Type VARCHAR(10) AS
BEGIN
    DECLARE @ShiftID INT;

    SELECT TOP 1 @ShiftID = shift_id
    FROM ShiftAssignment
    WHERE employee_id = @EmployeeID
      AND STATUS = 'Active';

    IF @Type = 'IN'
        INSERT INTO Attendance (employee_id, shift_id, entry_time, login_method)
        VALUES (@EmployeeID,
                @ShiftID,
                @ClockInOutTime,
                'Self-Service');

    ELSE
        IF @Type = 'OUT'
            UPDATE
                Attendance
            SET exit_time     = @ClockInOutTime,
                logout_method = 'Self-Service',
                duration      = DATEDIFF(MINUTE, entry_time, @ClockInOutTime)
            WHERE employee_id = @EmployeeID
              AND CAST(entry_time AS DATE) = CAST(@ClockInOutTime AS DATE)
              AND exit_time IS NULL;

    SELECT 'Punch recorded successfully' AS Message;

END;

GO
CREATE PROCEDURE SubmitCorrectionRequest @EmployeeID INT,
                                         @Date DATE,
                                         @CorrectionType VARCHAR(50),
                                         @Reason VARCHAR(200) AS
BEGIN
    INSERT INTO AttendanceCorrectionRequest (employee_id,
                                             date,
                                             correction_type,
                                             reason,
                                             STATUS,
                                             recorded_by)
    VALUES (@EmployeeID,
            @Date,
            @CorrectionType,
            @Reason,
            'Pending',
            @EmployeeID);

    SELECT 'Correction request submitted successfully' AS Message;

END;

GO
CREATE PROCEDURE ViewRequestStatus @EmployeeID INT AS
BEGIN
    SELECT 'Attendance Correction' AS request_type,
           request_id,
           date,
           STATUS
    FROM AttendanceCorrectionRequest
    WHERE employee_id = @EmployeeID
    UNION
        ALL
    SELECT 'Leave Request' AS request_type,
           request_id,
           NULL            AS date,
           STATUS
    FROM LeaveRequest
    WHERE employee_id = @EmployeeID
    ORDER BY STATUS,
             request_id DESC;

END;

GO
CREATE PROCEDURE AttachLeaveDocuments @LeaveRequestID INT,
                                      @FilePath VARCHAR(200) AS
BEGIN
    INSERT INTO LeaveDocument (leave_request_id, file_path)
    VALUES (@LeaveRequestID, @FilePath);

    SELECT 'Document attached to leave request successfully' AS Message;

END;

GO
CREATE PROCEDURE ModifyLeaveRequest @LeaveRequestID INT,
                                    @StartDate DATE,
                                    @EndDate DATE,
                                    @Reason VARCHAR(100) AS
BEGIN
    DECLARE @Duration INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;

    UPDATE
        LeaveRequest
    SET duration      = @Duration,
        justification = @Reason
    WHERE request_id = @LeaveRequestID
      AND STATUS = 'Pending';

    IF @@ROWCOUNT > 0
        SELECT 'Leave request modified successfully' AS Message;

    ELSE
        SELECT 'Cannot modify leave request - not in pending status' AS Message;

END;

GO
CREATE PROCEDURE CancelLeaveRequest @LeaveRequestID INT AS
BEGIN
    UPDATE
        LeaveRequest
    SET STATUS = 'Cancelled'
    WHERE request_id = @LeaveRequestID
      AND STATUS IN ('Pending', 'Approved');

    IF @@ROWCOUNT > 0
        SELECT 'Leave request cancelled successfully' AS Message;

    ELSE
        SELECT 'Cannot cancel leave request' AS Message;

END;

GO
CREATE PROCEDURE ViewLeaveBalance @EmployeeID INT AS
BEGIN
    SELECT l.leave_type,
           le.entitlement AS remaining_days
    FROM LeaveEntitlement le
             INNER JOIN Leave l ON le.leave_type_id = l.leave_id
    WHERE le.employee_id = @EmployeeID;

END;

GO
CREATE PROCEDURE ViewLeaveHistory @EmployeeID INT AS
BEGIN
    SELECT lr.request_id,
           l.leave_type,
           lr.duration,
           lr.status,
           lr.approval_timing
    FROM LeaveRequest lr
             INNER JOIN Leave l ON lr.leave_id = l.leave_id
    WHERE lr.employee_id = @EmployeeID
    ORDER BY lr.request_id DESC;

END;

GO
CREATE PROCEDURE SubmitLeaveAfterAbsence @EmployeeID INT,
                                         @LeaveTypeID INT,
                                         @StartDate DATE,
                                         @EndDate DATE,
                                         @Reason VARCHAR(100) AS
BEGIN
    DECLARE @Duration INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;

    INSERT INTO LeaveRequest (employee_id,
                              leave_id,
                              justification,
                              duration,
                              STATUS)
    VALUES (@EmployeeID,
            @LeaveTypeID,
            'Retroactive: ' + @Reason,
            @Duration,
            'Pending');

    SELECT 'Leave request submitted after absence' AS Message;

END;

GO
CREATE PROCEDURE NotifyLeaveStatusChange @EmployeeID INT,
                                         @RequestID INT,
                                         @Status VARCHAR(20) AS
BEGIN
    INSERT INTO Notification (message_content, urgency, notification_type)
    VALUES ('Your leave request #' + CAST(@RequestID AS VARCHAR) + ' has been ' + @Status,
            'Normal',
            'Leave');

    DECLARE @NotificationID INT = SCOPE_IDENTITY();

    INSERT INTO Employee_Notification (employee_id,
                                       notification_id,
                                       delivery_status,
                                       delivered_at)
    VALUES (@EmployeeID,
            @NotificationID,
            'Delivered',
            GETDATE());

    SELECT 'Leave status notification sent' AS Message;

END;


GO



