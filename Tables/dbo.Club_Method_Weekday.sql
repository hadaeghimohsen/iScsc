CREATE TABLE [dbo].[Club_Method_Weekday]
(
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Club_Method_Weekday_CODE] DEFAULT ((0)),
[CBMT_CODE] [bigint] NULL,
[WEEK_DAY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_CBMW]
   ON  [dbo].[Club_Method_Weekday]
   AFTER INSERT
AS 
BEGIN
	MERGE dbo.Club_Method_Weekday T
	USING (
	   SELECT *
	     FROM INSERTED I
	)S
	ON (T.CBMT_CODE = S.CBMT_CODE AND 
	    T.WEEK_DAY  = S.WEEK_DAY  AND
	    T.CODE      = S.CODE)
	WHEN MATCHED THEN
	   UPDATE
	      SET CRET_BY = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,CODE = dbo.GNRT_NVID_U();

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
CREATE TRIGGER [dbo].[CG$AUPD_CBMW]
   ON  [dbo].[Club_Method_Weekday]
   AFTER UPDATE
AS 
BEGIN
	MERGE dbo.Club_Method_Weekday T
	USING (
	   SELECT *
	     FROM INSERTED I
	)S
	ON (T.CBMT_CODE = S.CBMT_CODE AND 
	    T.WEEK_DAY  = S.WEEK_DAY  AND
	    T.CODE      = S.CODE)
	WHEN MATCHED THEN
	   UPDATE
	      SET MDFY_BY = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
   

   -- مشخص کردن نوع روز برنامه کلاسی   
   /*UPDATE dbo.Club_Method
      SET DAY_TYPE = CASE WHEN EXISTS(SELECT * FROM dbo.Club_Method_Weekday WHERE CBMT_CODE = dbo.Club_Method.CODE AND STAT = '002' AND WEEK_DAY IN ('001', '003', '005')) AND EXISTS(SELECT * FROM dbo.Club_Method_Weekday WHERE CBMT_CODE = dbo.Club_Method.CODE AND STAT = '002' AND WEEK_DAY IN ('002', '004', '006', '007')) THEN '003'
                          WHEN EXISTS(SELECT * FROM dbo.Club_Method_Weekday WHERE CBMT_CODE = dbo.Club_Method.CODE AND STAT = '002' AND WEEK_DAY IN ('001', '003', '005')) THEN '001'
                          WHEN EXISTS(SELECT * FROM dbo.Club_Method_Weekday WHERE CBMT_CODE = dbo.Club_Method.CODE AND STAT = '002' AND WEEK_DAY IN ('002', '004', '006', '007')) THEN '002'
                     END
         ,MTOD_STAT = CASE WHEN MTOD_STAT = '002' AND NOT EXISTS(SELECT * FROM dbo.Club_Method_Weekday WHERE CBMT_CODE = dbo.Club_Method.CODE AND STAT = '002') THEN '001'
                           ELSE MTOD_STAT
                      END
    WHERE EXISTS(
      SELECT *
        FROM INSERTED i
       WHERE dbo.Club_Method.CODE = I.Cbmt_Code
    );*/
END
GO
ALTER TABLE [dbo].[Club_Method_Weekday] ADD CONSTRAINT [PK_Club_Method_Weekday] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Club_Method_Weekday] ADD CONSTRAINT [FK_CBMW_CBMT] FOREIGN KEY ([CBMT_CODE]) REFERENCES [dbo].[Club_Method] ([CODE]) ON DELETE CASCADE
GO
