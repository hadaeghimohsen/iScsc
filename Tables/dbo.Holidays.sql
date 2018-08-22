CREATE TABLE [dbo].[Holidays]
(
[CODE] [bigint] NOT NULL,
[YEAR] [int] NULL,
[CYCL] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HLDY_DATE] [date] NULL,
[WEEK_DAY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HLDY_DESC] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_HLDY]
   ON  [dbo].[Holidays]
   AFTER INSERT 
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>228</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 228 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   -- 1397/01/28 * بررسی اینکه آیا تاریخی تکراری ثبت شده یا خیر   
   IF EXISTS(
      SELECT *
        FROM dbo.Holidays h, Inserted i
       WHERE h.HLDY_DATE = i.HLDY_DATE
         AND h.CODE != i.CODE
   )
   BEGIN
      RAISERROR(N'شما اجازه ثبت تاریخ تکراری نمی باشید، لطفا بررسی کنید', 16, 1);   
      RETURN;
   END;
   
   
	MERGE dbo.Holidays T
	USING (SELECT * FROM Inserted) S
	ON (T.HLDY_DATE = S.HLDY_DATE)
	WHEN MATCHED THEN 
	   UPDATE SET
	      t.CRET_BY = UPPER(SUSER_NAME())
	     ,t.CRET_DATE = GETDATE()
	     ,t.CODE = dbo.GNRT_NVID_U();
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_HLDY]
   ON  [dbo].[Holidays]
   AFTER UPDATE 
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>229</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 229 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END;

   -- 1397/01/28 * بررسی اینکه آیا تاریخی تکراری ثبت شده یا خیر   
   IF EXISTS(
      SELECT *
        FROM dbo.Holidays h, Inserted i
       WHERE h.HLDY_DATE = i.HLDY_DATE
         AND h.CODE != i.CODE
   )
   BEGIN
      RAISERROR(N'شما اجازه ثبت تاریخ تکراری نمی باشید، لطفا بررسی کنید', 16, 1);   
      RETURN;
   END
   
	MERGE dbo.Holidays T
	USING (SELECT * FROM Inserted) S
	ON (T.CODE = s.CODE)
	WHEN MATCHED THEN 
	   UPDATE SET
	      t.MDFY_BY = UPPER(SUSER_NAME())
	     ,t.MDFY_DATE = GETDATE()
	     ,T.YEAR = SUBSTRING(dbo.GET_MTOS_U(s.HLDY_DATE), 1, 4)
	     ,T.CYCL = dbo.GET_PSTR_U(SUBSTRING(dbo.GET_MTOS_U(s.HLDY_DATE), 6, 2), 3)
	     ,T.WEEK_DAY = dbo.GET_PSTR_U( DATEPART(WEEKDAY, s.HLDY_DATE), 3);
END
GO
ALTER TABLE [dbo].[Holidays] ADD CONSTRAINT [PK_HLDY] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
