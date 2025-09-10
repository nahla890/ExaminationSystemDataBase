-- =========================
-- Department Table 
-- =========================
create table ITI.Department (
    DeptID int identity,
    [Name] nvarchar(100) NOT NULL,
	Constraint Department_PK primary key (DeptID),
	-- check name
	Constraint DeptNameLengthCheck check (len([Name]) >= 3),
    Constraint DeptNameNoSpacesStart check ([Name] NOT LIKE ' %')
)on ExaminationSystemD_FG2;

-- =========================
-- Intake Table
-- =========================
create table ITI.Intake (
    IntakeID int identity,
    IntakeYear date,
	Constraint Intake_PK primary key (IntakeID),
	Constraint IntakeDate_Check check (IntakeYear >= '2000-01-01')
)on [PRIMARY];

-- =========================
-- Track Table 
-- =========================

create table ITI.Track (
    TrackID int identity,
    [Name] nvarchar(100) NOT NULL,
	DeptID int,
	Constraint Track_PK primary key (TrackID),
	constraint BranchDept_FK foreign key (DeptID) references ITI.Department(DeptID),
	-- check name
	Constraint TrackNameLengthCheck check (len([Name]) >= 3),
    Constraint TrackNameNoSpacesStart check ([Name] not like ' %')
)on [PRIMARY];

-- =========================
-- Branch Table
-- =========================
create table ITI.Branch (
    BranchID int identity,
    [Name] nvarchar(50) NOT NULL,
	Constraint Branch_PK primary key (BranchID),
	-- check name
	Constraint BranchNameLengthCheck check (len([Name]) >= 3),
    Constraint BranchNameNoSpacesStart check ([Name] not like ' %'),

)on [PRIMARY];

-- =========================
-- BranchTrack Table 
-- =========================
create table ITI.BranchTrack (
    BranchID int,
    TrackID int,
	constraint BranchTrack_PK primary key (BranchID,TrackID),
	constraint BranchTrackBranch_FK foreign key (BranchID) references ITI.Branch(BranchID),
	constraint BranchTrackTrack_FK foreign key (TrackID) references ITI.Track(TrackID),
)on ExaminationSystemD_FG1;
-- =========================
-- Class Table (depends on Intake, Track, Branch, Course)
-- =========================
create table ITI.Class (
    ID int identity,
    IntakeID int,
    TrackID int,
    BranchID int,
	constraint Class_PK primary key (ID),
    constraint ClassIntakeID_FK foreign key (IntakeID) references ITI.Intake(IntakeID),
    constraint ClassTrackID_FK foreign key (TrackID) references ITI.Track(TrackID),
    constraint ClassBranchID_FK foreign key (BranchID) references ITI.Branch(BranchID),
)on ExaminationSystemD_FG2;
-- =========================
-- Course Table (independent)
-- =========================
create table Courses.Course (
	CourseID int identity,
    [Name] nvarchar(100) ,
    MaxDegree int NOT NULL,
    MinDegree int NOT NULL,
    [Description] nvarchar(max),
	Constraint Course_PK primary key (CourseID),
	Constraint unique_CourseName unique ([Name])
)on ExaminationSystemD_FG2;

-- =========================
-- Stud_Course Table (Many-to-Many Student <-> Course)
-- =========================
create table Courses.CourseInClass (
    ClassID int NOT NULL,
    CourseID int NOT NULL,
	constraint Class_Course_PK primary key (ClassID,CourseID),
	constraint Class_CourseStudent_FK foreign key (ClassID) references ITI.Class(ID),
    constraint ClassCourse_FK foreign key (CourseID) references Courses.Course(CourseID),
)on ExaminationSystemD_FG1;

-- =========================
-- Users Table (independent)
-- =========================
create table Person.[User] (
    UserID int ,
    Username nvarchar(100) NOT NULL,
	[Password] nvarchar(10) NOT NULL,
    --PasswordHash varbinary(64) NOT NULL,
    --Salt varbinary(16) NOT NULL,
	Name nvarchar(100) NOT NULL,
    Email nvarchar(50) ,
    Phone nchar(11),
    Role nvarchar(20) NOT NULL,
	 Age int,
	Constraint User_PK primary key (UserID),
	Constraint unique_Username unique (Username),
	Constraint unique_Email unique (Email),
	 -- Phone Checks
    Constraint UserPhonesCheckLength check (len(Phone) = 11),
    Constraint UserPhonesCheckLike check (Phone like '01%'),
    Constraint UserPhonesOnlyDigits check (Phone not like '%[^0-9]%'),
    -- Username Checks
    Constraint UserNameLengthCheck check (len(Username) >= 5),
    Constraint UserNameNoSpacesStart check (Username not like ' %'),
	-- Password Checks
    Constraint PasswordLengthCheck check (len([Password]) >= 8),
    Constraint PasswordContainsNumber check ([Password] like '%[0-9]%'),
    Constraint PasswordContainsLetter check ([Password] like '%[A-Za-z]%'),
    -- Email Checks
    Constraint EmailFormatCheck check (Email LIKE '%@%.%'),
	--Role & Age Check
	Constraint RoleCheck check ([Role] in ('Student', 'Instructor', 'Training Manager')),
	Constraint AgeCheck check (Age between 22 and 65),
)on [PRIMARY];

-- =========================
-- Student Table (depends on User, Track, Branch, Intake)
-- =========================
create table Person.Student (
    StdID int,
    ClassID int,
   
	Constraint Student_PK primary key (StdID),
	constraint StudentInClass_FK foreign key (ClassID) references ITI.Class(ID),
	constraint UserStdID_FK foreign key (StdID) references Person.[User](UserID)

)on [PRIMARY];

-- =========================
-- Instructor Table (depends on User)
-- =========================
create table Person.Instructor (
    InstructorID int,
	ManagerID int,

	Constraint Instructor_PK primary key (InstructorID),
	constraint UserInstructorID_FK foreign key (InstructorID) references Person.[User](UserID),
    constraint Manager_FK foreign key (ManagerID) references Person.Instructor(InstructorID)
)on [PRIMARY];


-- =========================
-- InstructorTeachCourse Table (depends on Instructor & Course)
-- =========================
create table Courses.InstructorTeachCourse (
    InstructorID int,
    CourseID int not null,
    TeachYear date,
    constraint InstructorTeachCourse_PK primary key (InstructorID, CourseID, TeachYear),
    constraint Instructor_FK foreign key (InstructorID) references Person.Instructor(InstructorID),
    constraint  CourseName_FK foreign key (CourseID) references Courses.Course(CourseID),
	constraint IntakeDate_Check check (TeachYear >= '2000-01-01')
)on ExaminationSystemD_FG1;


-- =========================
-- Exam Table (depends on Instructor, Course, Intake, Branch, Track)
-- =========================

create table Exams.Exam (
    ExamID int identity,
    StartTime time,
    EndTime time,
    ExamDate date,
    allow_back nvarchar(5) NOT NULL check (allow_back in ('True','False')),
	show_result nvarchar(5) NOT NULL check (show_result in ('True','False')),
	random_order nvarchar(5) NOT NULL check (random_order in ('True','False')),
    instructor_ID int,
	CourseID int,
	ClassID int,

	constraint Exam_PK primary key (ExamID),
    constraint  instructor_ID_FK foreign key (instructor_ID) references Person.Instructor(InstructorID),
    constraint  CourseName_FK foreign key (CourseID) references Courses.Course(CourseID),
    constraint  ClassExamID_FK foreign key (ClassID) references ITI.Class(ID),
    
	-- Time & Date Check
	constraint EndTime_Check check (EndTime > StartTime),
	constraint ExamDate_Check check (ExamDate >= cast(getDate() as date)),

)on ExaminationSystemD_FG2;

-- =========================
-- Question Table (independent)
-- =========================
create table Exams.Question (
    QuestionNO int identity,
    body nvarchar(max) NOT NULL,
    [Type] nvarchar(20) check ([Type] in ('MCQ', 'T/F', 'Text')),
    CorrectAnswer nvarchar(5),
    BestAnswer nvarchar(max),
	constraint Question_PK primary key (QuestionNO),

)on ExaminationSystemD_FG2;

-- =========================
-- Exam_Question Table (depends on Exam & Question)
-- =========================
create table Exams.Exam_Question (
    ExamID int,
    QuestionNO int,
    Mark int NOT NULL check (Mark > 0),
    constraint Exam_Question_PK primary key (ExamID, QuestionNO),
    constraint ExamID_FK foreign key (ExamID) references Exams.Exam(ExamID),
    constraint QuestionNO_FK foreign key (QuestionNO) references Exams.Question(QuestionNO)
)on ExaminationSystemD_FG1;

-- =========================
-- Answer Table (depends on Student, Exam, Question)
-- =========================
create table Exams.Answer (
    StdID int,
    ExamID int,
    QuestionNO int,
    Answer nvarchar(MAX),
    isCorrect nvarchar(5) check (isCorrect in ('True','False')) ,
    constraint Answer_PK primary key (StdID, ExamID, QuestionNO),
    constraint AnswerStdID_FK foreign key (StdID) references Person.Student(StdID),
    constraint AnswerExamID_FK foreign key (ExamID) references Exams.Exam(ExamID),
    constraint AnswerQuestionNO_FK foreign key (QuestionNO) references Exams.Question(QuestionNO)
)on ExaminationSystemD_FG1;
-- =========================
-- Stud_Exam Table (depends on Student, Exam)
-- =========================
create table Exams.Stud_Exam (
    StudID int,
    ExamID int,
    [Type] nvarchar(10)check ([Type] in ('Passed', 'Corrective', 'Pending')),
    Total_Mark int,
    constraint Stud_Exam_PK primary key (StudID, ExamID),
    constraint Stud_ExamStudID_FK foreign key (StudID) references Person.Student(StdID),
    constraint Stud_ExamExamID_FK foreign key (ExamID) references Exams.Exam(ExamID)
)on ExaminationSystemD_FG1;
