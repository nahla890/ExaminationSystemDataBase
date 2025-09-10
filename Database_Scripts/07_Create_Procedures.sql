--1
create procedure sp_StudentTakeExam
    @ExamID int, 
    @StudentID int
as
begin
    IF NOT EXISTS (
        SELECT 1 FROM Exams.Stud_Exam WHERE StudID = @StudentID AND ExamID = @ExamID
    )
    begin
        INSERT INTO Exams.Stud_Exam (StudID, ExamID, [Type], Total_Mark)
        VALUES (@StudentID, @ExamID, 'Pending', 0);
    end
end;
go

--2
create procedure sp_SubmitAnswer
    @ExamID int, 
    @QuestionID int, 
    @StudentID int, 
    @Answer nvarchar(max)
as
begin
    declare @Correct nvarchar(5);
    set @Correct = case 
                      when [dbo].[fn_CheckAnswer](@QuestionID, @Answer) = 1 
                      then 'True' 
                      else 'False' 
                   end;
    insert into Exams.Answer (StdID, ExamID, QuestionNO, Answer, isCorrect)
    values (@StudentID, @ExamID, @QuestionID, @Answer, @Correct);
end;
go

--3
create procedure sp_ViewMyResults
    @StudentID int
as
begin
    select se.ExamID, c.Name as CourseName, se.Total_Mark, se.[Type]
    from Exams.Stud_Exam se
    join Exams.Exam e on se.ExamID = e.ExamID
    join Courses.Course c on e.CourseID = c.CourseID
    where se.StudID = @StudentID;
end;
go
--4 sp_AddQuestion
CREATE PROCEDURE sp_AddQuestion
    @Body NVARCHAR(MAX),
    @Type NVARCHAR(20),
    @CorrectAnswer NVARCHAR(5),
    @BestAnswer NVARCHAR(MAX)
AS
BEGIN
    INSERT INTO Exams.Question (Body, Type, CorrectAnswer, BestAnswer)
    VALUES (@Body, @Type, @CorrectAnswer, @BestAnswer);
END;

go
--5 sp_UpdateQuestion
CREATE PROCEDURE sp_UpdateQuestion
    @QuestionID INT,
    @Body NVARCHAR(MAX),
    @Type NVARCHAR(20),
    @CorrectAnswer NVARCHAR(5),
    @BestAnswer NVARCHAR(MAX)
AS
BEGIN
    UPDATE Exams.Question
    SET Body = @Body,
        Type = @Type,
        CorrectAnswer = @CorrectAnswer,
        BestAnswer = @BestAnswer
    WHERE QuestionNO = @QuestionID;
END;

go
--6 sp_DeleteQuestion
CREATE PROCEDURE sp_DeleteQuestion
    @QuestionID INT
AS
BEGIN
    DELETE FROM Exams.Question
    WHERE QuestionNO = @QuestionID;
END;

go
--7 sp_CreateExam
CREATE PROCEDURE sp_CreateExam
    @CourseID INT,
    @InstructorID INT,
    @ExamDate DATE,
    @StartTime TIME,
    @EndTime TIME,
    @ClassID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Courses.InstructorTeachCourse itc
        WHERE itc.CourseID = @CourseID
          AND itc.InstructorID = @InstructorID
    )
    BEGIN
        RAISERROR('Instructor is not assigned to teach this course. Exam cannot be created.', 16, 1);
        RETURN;
    END;

    INSERT INTO Exams.Exam (
        StartTime, EndTime, ExamDate, allow_back, show_result, random_order,
        instructor_ID, CourseID,ClassID
    )
    VALUES (
        @StartTime, @EndTime, @ExamDate, 'True', 'True', 'False',
        @InstructorID, @CourseID, @ClassID
    );
END;
GO


go
--8-sp_Add ExamQuestion
CREATE PROCEDURE sp_AddExamQuestion
    @ExamID INT,
    @QuestionNO INT,
    @Mark INT
AS
BEGIN
    BEGIN TRY
        DECLARE @CourseID INT;
        DECLARE @MaxDegree INT;
        DECLARE @CurrentTotal INT;

        SELECT @CourseID = CourseID 
        FROM Exams.Exam
        WHERE ExamID = @ExamID;

        SELECT @MaxDegree = MaxDegree
        FROM Courses.Course
        WHERE CourseID = @CourseID;

        SELECT @CurrentTotal = ISNULL(SUM(Mark), 0)
        FROM Exams.Exam_Question
        WHERE ExamID = @ExamID;

        IF (@CurrentTotal + @Mark) > @MaxDegree
        BEGIN
            RAISERROR('Cannot add question: total marks will exceed course MaxDegree.', 16, 1);
            RETURN;
        END

        INSERT INTO Exams.Exam_Question (ExamID, QuestionNO, Mark)
        VALUES (@ExamID, @QuestionNO, @Mark);

        PRINT 'Question assigned to exam successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Error assigning question to exam: ' + ERROR_MESSAGE();
    END CATCH
END;

go
--=================================================
--9 sp_AssignExamToStudents
create procedure sp_AssignExamToStudents
    @ExamID int
as
begin
    set nocount on;
    declare @CourseID int;

    select @CourseID = CourseID
    from Exams.Exam
    where ExamID = @ExamID;

    if @CourseID is null
    begin
        raiserror('Invalid ExamID: Exam not found.', 16, 1);
        return;
    end;
    insert into Exams.Stud_Exam (StudID, ExamID, [Type], Total_Mark)
    select sc.StdID, @ExamID, 'Pending', 0
    from Courses.Stud_Course sc
    where sc.CourseID = @CourseID
      and not exists (
            select 1 
            from Exams.Stud_Exam se
            where se.StudID = sc.StdID 
              and se.ExamID = @ExamID
      );
    print 'Exam assigned successfully to all students in the course.';
end;
go


--10 sp_CorrectTextAnswer
CREATE PROCEDURE sp_CorrectTextAnswer
    @StdID INT,
    @ExamID INT,
    @QuestionNO INT,
    @Mark INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Exams.Answer
    SET isCorrect = CASE WHEN @Mark > 0 THEN 'True' ELSE 'False' END
    WHERE StdID = @StdID AND ExamID = @ExamID AND QuestionNO = @QuestionNO;
    UPDATE se
    SET Total_Mark = ISNULL(t.TotalMark, 0)
    FROM Exams.Stud_Exam se
    CROSS APPLY (
        SELECT SUM(eq.Mark) AS TotalMark
        FROM Exams.Answer a
        JOIN Exams.Exam_Question eq 
            ON a.QuestionNO = eq.QuestionNO 
           AND a.ExamID = eq.ExamID
        WHERE a.StdID = @StdID 
          AND a.ExamID = @ExamID 
          AND a.isCorrect = 'True'
    ) t
    WHERE se.StudID = @StdID 
      AND se.ExamID = @ExamID;
END;
GO


go
--11 sp_GetExamReport
CREATE PROCEDURE sp_GetExamReport
    @ExamID INT
AS
BEGIN
     SELECT S.StdID, U.Name AS StudentName, SE.Total_Mark
    FROM Exams.Stud_Exam SE
    JOIN Person.Student S ON SE.StudID = S.StdID
    JOIN Person.[User] U ON S.StdID = U.UserID
    WHERE SE.ExamID = @ExamID;
END;

go
--12 sp_EvaluateStudentExam
CREATE PROCEDURE sp_EvaluateStudentExam
    @ExamID INT,
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalMark INT = 0;
	DECLARE @MinDegree INT;
    DECLARE @CourseID INT;
    DECLARE @ResultType NVARCHAR(10);

    SELECT @TotalMark = ISNULL(SUM(EQ.Mark), 0)
    FROM Exams.Answer A
    JOIN Exams.Exam_Question EQ 
        ON A.QuestionNO = EQ.QuestionNO AND A.ExamID = EQ.ExamID
    WHERE A.StdID = @StudentID AND A.ExamID = @ExamID AND A.isCorrect = 'True';

    SELECT @CourseID = CourseID
    FROM Exams.Exam
    WHERE ExamID = @ExamID;

    SELECT @MinDegree = MinDegree
    FROM Courses.Course
    WHERE CourseID = @CourseID;

    IF (@TotalMark >= @MinDegree) 
        SET @ResultType = 'Passed';
    ELSE 
        SET @ResultType = 'Corrective';

    IF EXISTS (
        SELECT 1 FROM Exams.Stud_Exam
        WHERE StudID = @StudentID AND ExamID = @ExamID
    )
    BEGIN
        UPDATE Exams.Stud_Exam
        SET Total_Mark = @TotalMark,
            [Type] = @ResultType
        WHERE StudID = @StudentID AND ExamID = @ExamID;
    END
    ELSE
    BEGIN
        INSERT INTO Exams.Stud_Exam (StudID, ExamID, [Type], Total_Mark)
        VALUES (@StudentID, @ExamID, @ResultType, @TotalMark);
    END;
END;

go

--13 sp_Add Instructor
create or alter procedure sp_AddInstructor
    @Username nvarchar(100),
    @Password nvarchar(10),
    @Name nvarchar(100),
    @Email nvarchar(50),
    @Phone nchar(11),
    @Age int,
    @ManagerID int = null
as
begin
    set nocount on;

    declare @NewUserID int;
    SELECT @NewUserID = ISNULL(MAX(UserId), 0) + 1 FROM [Person].[User];
    declare @Role nvarchar(20);

    if @ManagerID is null
        set @Role = 'Training Manager';
    else
        set @Role = 'Instructor';

    begin try
        insert into Person.[User] (UserID, Username, [Password], Name, Email, Phone, Role, Age)
        values (@NewUserID,@Username, @Password, @Name, @Email, @Phone, @Role, @Age);

        

        if @NewUserID is null
        begin
            raiserror('User insertion failed, Instructor not created.',16,1);
            return;
        end

        insert into Person.Instructor (InstructorID, ManagerID)
        values (@NewUserID, @ManagerID);
    end try
    begin catch
        raiserror('User insertion failed, Instructor not created.',16,1);
        return;
    end catch
end;
go

--14 sp_UpdateInstructor
create PROCEDURE sp_UpdateInstructor
    @InstructorID INT,
    @Username NVARCHAR(100) = NULL,
    @Password NVARCHAR(10) = NULL,
    @Name NVARCHAR(100) = NULL,
    @Email NVARCHAR(50) = NULL,
    @Phone NCHAR(11) = NULL,
    @Age INT = NULL,
    @ManagerID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Role NVARCHAR(20);

    IF @ManagerID IS NULL
        SET @Role = 'Training Manager';
    ELSE
        SET @Role = 'Instructor';

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Person.Instructor WHERE InstructorID = @InstructorID)
        BEGIN
            RAISERROR('Instructor not found, update aborted.', 16, 1);
            RETURN;
        END

        UPDATE Person.[User]
        SET 
            Username = ISNULL(@Username, Username),
            [Password] = ISNULL(@Password, [Password]),
            Name     = ISNULL(@Name, Name),
            Email    = ISNULL(@Email, Email),
            Phone    = ISNULL(@Phone, Phone),
            Age      = ISNULL(@Age, Age),
            Role     = @Role
        WHERE UserID = @InstructorID;

        UPDATE Person.Instructor
        SET ManagerID = ISNULL(@ManagerID, ManagerID)
        WHERE InstructorID = @InstructorID;
    END TRY
    BEGIN CATCH
        RAISERROR('Instructor update failed.', 16, 1);
        RETURN;
    END CATCH
END;

go
--15 sp_DeleteInstructor
create procedure sp_DeleteInstructor
    @InstructorID int
as
begin
    if not exists (select 1 from Person.Instructor where InstructorID = @InstructorID)
    begin
        raiserror('Instructor not found.', 16, 1);
        return;
    end
    delete from Person.Instructor
    where InstructorID = @InstructorID;
    delete from Person.[User]
    where UserID = @InstructorID;
end;
go
--16 sp_AddCourse
create procedure sp_AddCourse
    @Name nvarchar(100),
    @MaxDegree int,
    @MinDegree int,
    @Description nvarchar(max) = null
as
begin
    set nocount on;
    if exists (select 1 from Courses.Course where [Name] = @Name)
    begin
        raiserror('Course name already exists.', 16, 1);
        return;
    end

    insert into Courses.Course ([Name], MaxDegree, MinDegree, [Description])
    values (@Name, @MaxDegree, @MinDegree, @Description);
end;
go
--17 sp_UpdateCourse
create procedure sp_UpdateCourse
    @CourseID int,
    @Name nvarchar(100) = null,
    @MaxDegree int = null,
    @MinDegree int = null,
    @Description nvarchar(max) = null
as
begin
    set nocount on;
    if not exists (select 1 from Courses.Course where CourseID = @CourseID)
    begin
        raiserror('Course not found.', 16, 1);
        return;
    end
    if @Name is not null and exists (select 1 from Courses.Course where [Name] = @Name and CourseID <> @CourseID)
    begin
        raiserror('Another course with this name already exists.', 16, 1);
        return;
    end

    update Courses.Course
    set 
        [Name] = isnull(@Name, [Name]),
        MaxDegree = isnull(@MaxDegree, MaxDegree),
        MinDegree = isnull(@MinDegree, MinDegree),
        [Description] = isnull(@Description, [Description])
    where CourseID = @CourseID;
end;
go
--18 sp_DeleteCourse
create procedure sp_DeleteCourse
    @CourseID int
as
begin
    set nocount on;
    if not exists (select 1 from Courses.Course where CourseID = @CourseID)
    begin
        raiserror('Course not found.', 16, 1);
        return;
    end
    delete from Courses.Course
    where CourseID = @CourseID;
end;
go

--19 sp_AddBranch
create procedure sp_AddBranch
    @Name nvarchar(50)
as
begin
    set nocount on;
    if len(ltrim(rtrim(@Name))) < 3
    begin
        raiserror('Branch name must be at least 3 characters.', 16, 1);
        return;
    end
    insert into ITI.Branch([Name])
    values (ltrim(rtrim(@Name)));
end;
go
--20 sp_UpdateBranch
create procedure sp_UpdateBranch
    @BranchID int,
    @Name nvarchar(50) = null
as
begin
    set nocount on;
    if not exists (select 1 from ITI.Branch where BranchID = @BranchID)
    begin
        raiserror('Branch not found.', 16, 1);
        return;
    end
    update ITI.Branch
    set [Name] = case when @Name is not null then ltrim(rtrim(@Name)) else [Name] end
    where BranchID = @BranchID;
end;
go
--21 sp_AddTrack
create procedure sp_AddTrack
    @Name nvarchar(100),
    @DeptID int
as
begin
    set nocount on;
    if len(ltrim(rtrim(@Name))) < 3
    begin
        raiserror('Track name must be at least 3 characters.', 16, 1);
        return;
    end
    if not exists (select 1 from ITI.Department where DeptID = @DeptID)
    begin
        raiserror('Invalid Department ID.', 16, 1);
        return;
    end
    insert into ITI.Track([Name], [DeptID])
    values (ltrim(rtrim(@Name)), @DeptID);
end;
go
--22 sp_UpdateTrack
create procedure sp_UpdateTrack
    @TrackID int,
    @Name nvarchar(100) = null,
    @DeptID int = null
as
begin
    set nocount on;
    if not exists (select 1 from ITI.Track where TrackID = @TrackID)
    begin
        raiserror('Track not found.', 16, 1);
        return;
    end
    if @Name is not null and len(ltrim(rtrim(@Name))) < 3
    begin
        raiserror('Track name must be at least 3 characters.', 16, 1);
        return;
    end
    if @DeptID is not null and not exists (select 1 from ITI.Department where DeptID = @DeptID)
    begin
        raiserror('Invalid Department ID.', 16, 1);
        return;
    end
    update ITI.Track
    set 
        [Name] = isnull(ltrim(rtrim(@Name)), [Name]),
        [DeptID] = isnull(@DeptID, [DeptID])
    where TrackID = @TrackID;
end;
go
--23 sp_AssignTrackToBranch
create procedure sp_AssignTrackToBranch
    @BranchID int,
    @TrackID int
as
begin
    set nocount on;
    if not exists (select 1 from ITI.Branch where BranchID = @BranchID)
    begin
        print 'Branch ID not found.';
        return;
    end
    if not exists (select 1 from ITI.Track where TrackID = @TrackID)
    begin
        print 'Track ID not found.';
        return;
    end
    if exists (
        select 1 
        from ITI.BranchTrack
        where BranchID = @BranchID and TrackID = @TrackID
    )
    begin
        print 'This Track is already assigned to the Branch.';
        return;
    end
    insert into ITI.BranchTrack (BranchID, TrackID)
    values (@BranchID, @TrackID);

    print 'Track assigned to Branch successfully.';
end;

go
--24 sp_AddIntake
create procedure sp_AddIntake
    @IntakeYear date
as
begin
    set nocount on;
    if @IntakeYear < '2000-01-01'
    begin
        raiserror('Intake year must be >= 2000.', 16, 1);
        return;
    end
    insert into ITI.Intake(IntakeYear)
    values (@IntakeYear);
end;
go
--25-sp_AddDepartment
create procedure sp_AddDepartment
    @Name nvarchar(100)
as
begin
    set nocount on;
    if len(ltrim(rtrim(@Name))) < 3
    begin
        raiserror('Department name must be at least 3 characters.', 16, 1);
        return;
    end
    if exists (select 1 from ITI.Department where [Name] = ltrim(rtrim(@Name)))
    begin
        raiserror('Department name already exists.', 16, 1);
        return;
    end
    insert into ITI.Department([Name])
    values (ltrim(rtrim(@Name)));
end;
go
--26-sp_UpdateDepartment
create procedure sp_UpdateDepartment
    @DeptID int,
    @Name nvarchar(100) = null
as
begin
    set nocount on;
    if not exists (select 1 from ITI.Department where DeptID = @DeptID)
    begin
        raiserror('Department not found.', 16, 1);
        return;
    end
    if @Name is not null
    begin
        if len(ltrim(rtrim(@Name))) < 3
        begin
            raiserror('Department name must be at least 3 characters.', 16, 1);
            return;
        end
        if exists (select 1 from ITI.Department where [Name] = ltrim(rtrim(@Name)) and DeptID <> @DeptID)
        begin
            raiserror('Another department with this name already exists.', 16, 1);
            return;
        end
    end
    update ITI.Department
    set [Name] = isnull(ltrim(rtrim(@Name)), [Name])
    where DeptID = @DeptID;
end;

go

--27 sp_AssignInstructorToCourse(@CourseID, @InstructorID, @Year) →
create procedure sp_AssignInstructorToCourse
    @CourseID int,
    @InstructorID int,
    @Year date
as
begin
    set nocount on;
    if not exists (select 1 from Courses.Course where CourseID = @CourseID)
    begin
        raiserror('Course not found.', 16, 1);
        return;
    end
    if not exists (select 1 from Person.Instructor where InstructorID = @InstructorID)
    begin
        raiserror('Instructor not found.', 16, 1);
        return;
    end
    if not exists (select 1 from ITI.Intake where IntakeYear = @Year)
    begin
        raiserror('Year not found in Intake table.', 16, 1);
        return;
    end

    if exists (
        select 1 from Courses.InstructorTeachCourse
        where CourseID = @CourseID and TeachYear = @Year
    )
    begin
        raiserror('This course is already assigned to an instructor for the same year.', 16, 1);
        return;
    end

    insert into Courses.InstructorTeachCourse (InstructorID, CourseID, TeachYear)
    values (@InstructorID, @CourseID, @Year);
end;
go
--28 Add Student
create procedure sp_AddStudent
    @Name nvarchar(100),
    @Username nvarchar(100),
    @Password nvarchar(10),
    @Email nvarchar(50),
    @Phone nchar(11),
    @Age int,
    @ClassID int
as
begin
    declare @NewUserID int;
	 SELECT @NewUserID = ISNULL(MAX(UserId), 0) + 1 FROM [Person].[User];
    if not exists (select 1 from ITI.Class where ID = @ClassID)
    begin
        raiserror('Invalid Intake ID.', 16, 1);
        return;
    end
    
    insert into Person.[User] (UserID, Username, [Password], Name, Email, Phone, Role, Age)
    values (@NewUserID,@Username, @Password, @Name, @Email, @Phone, 'Student', @Age);

    insert into Person.Student ([StdID], ClassID)
    values (@NewUserID, @ClassID);
end;
go

--29 Course Summary Report
CREATE PROCEDURE sp_GetCourseSummary
    @CourseID int
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Courses.Course WHERE CourseID = @CourseID)
    BEGIN
        RAISERROR('Course not found.', 16, 1);
        RETURN;
    END;

    SELECT 
        c.CourseID,
        c.[Name] AS CourseName,
        c.MaxDegree,
        c.MinDegree,
        c.[Description]
    FROM Courses.Course c
    WHERE c.CourseID = @CourseID;

    SELECT 
        e.ExamID,
        e.ExamDate,
        e.StartTime,
        e.EndTime
    FROM Exams.Exam e
    WHERE e.CourseID = @CourseID;

    SELECT 
        se.StudID,
        u.Name AS StudentName,
        se.ExamID,
        e.ExamDate,
        se.Total_Mark,
        se.[Type]
    FROM Exams.Stud_Exam se
    JOIN Exams.Exam e ON e.ExamID = se.ExamID
    JOIN Person.[User] u ON u.UserID = se.StudID
    WHERE e.CourseID = @CourseID;
END;
GO

go
--30 sp_RegisterStudentInCourse
create procedure sp_AssignCourseToClass
    @ClassID int,
    @CourseID int
as
begin
    set nocount on;

    if not exists (
        select 1 
        from Courses.CourseInClass
        where ClassID = @ClassID and CourseID = @CourseID
    )
    begin
        insert into Courses.CourseInClass (ClassID, CourseID)
        values (@ClassID, @CourseID);
    end
    else
    begin
        print 'Course already registered in this Class.';
    end
end;
go

CREATE OR ALTER PROCEDURE sp_AddNewClass
    @IntakeID INT,
    @TrackID INT,
    @BranchID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO ITI.Class (IntakeID, TrackID, BranchID)
        VALUES (@IntakeID, @TrackID, @BranchID);

        PRINT 'New class added successfully.';
    END TRY
    BEGIN CATCH
        RAISERROR('Class insertion failed.', 16, 1);
        RETURN;
    END CATCH
END;
