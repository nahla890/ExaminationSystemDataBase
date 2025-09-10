--  All Functions 
-- ============================================
--1
create function fn_CheckAnswer(@QuestionID int, @StudentAnswer nvarchar(max))
returns int
as
begin
    declare @CorrectAnswer nvarchar(max); 
    declare @BestAnswer nvarchar(max);
    declare @Result int;

    select 
        @CorrectAnswer = CorrectAnswer, 
        @BestAnswer = BestAnswer
    from Exams.Question 
    where QuestionNO = @QuestionID;

    if (@CorrectAnswer is null)
    begin
        if (@BestAnswer is null) 
            set @Result = 0;
        else if (@BestAnswer like '%' + ltrim(rtrim(@StudentAnswer)) + '%')
            set @Result = 1;
        else 
            set @Result = 0;
    end
    else
    begin
        if (ltrim(rtrim(@CorrectAnswer)) = ltrim(rtrim(@StudentAnswer)))
            set @Result = 1;
        else 
            set @Result = 0;
    end

    return @Result;
end;

go
--2 fn_GetCourseMaxDegree
CREATE FUNCTION fn_GetCourseMaxDegree (
    @CourseID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Max INT;
    SELECT @Max = MaxDegree FROM Courses.Course WHERE CourseID = @CourseID;
    RETURN @Max;
END;

go
--3 fn_StudentTotalDegree
CREATE FUNCTION fn_StudentTotalDegree (
    @StudentID INT,
    @CourseID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Total INT;
    SELECT @Total = SUM(SE.Total_Mark)
    FROM Exams.Stud_Exam SE
    JOIN Exams.Exam E ON SE.ExamID = E.ExamID
    WHERE SE.StudID = @StudentID AND E.CourseID = @CourseID;
    RETURN @Total;
END;

go

--4 fn_GetStudentCountByTrack
CREATE FUNCTION fn_GetStudentCountByTrack (
    @TrackID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) FROM ITI.Class  WHERE TrackID = @TrackID;
    RETURN @Count;
END;
go
--5 fn_GetInstructorLoad
CREATE FUNCTION fn_GetInstructorLoad (
    @InstructorID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    SELECT @Count = COUNT(*) FROM Courses.InstructorTeachCourse WHERE InstructorID = @InstructorID;
    RETURN @Count;
END;
go
