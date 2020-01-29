CREATE TABLE [dbo].[Payment_Detail_Commodity_Sale]
(
[PYDT_CODE] [bigint] NULL,
[PROD_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[SALE_DATE] [datetime] NULL,
[SALE_AFTR_PROD_DAY] [int] NULL,
[SALE_BEFR_EXPR_DAY] [int] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PDCS]
   ON  [dbo].[Payment_Detail_Commodity_Sale]
   AFTER INSERT
AS 
BEGIN
   BEGIN TRY
   BEGIN TRANSACTION [T_CG$AINS_PDCS]
   IF (
      SELECT COUNT(*)
        FROM dbo.Payment_Detail_Commodity_Sale t, Inserted s
       WHERE t.PYDT_CODE = s.PYDT_CODE 
         AND s.PROD_CODE = s.PROD_CODE
   ) > 1
   BEGIN
      RAISERROR(N'این کالا قبلا در ردیف فروش قرار گرفته است', 16, 1);
      RETURN;
   END
   
	MERGE dbo.Payment_Detail_Commodity_Sale T
	USING (SELECT * FROM Inserted) S
	ON (t.PYDT_CODE = s.PYDT_CODE AND 
	    t.PROD_CODE = s.PROD_CODE AND
	    t.CODE = s.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.CRET_BY = UPPER(SUSER_NAME()),
	      T.CRET_DATE = GETDATE(),
	      T.CODE = CASE S.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE S.CODE END,
	      T.SALE_DATE = GETDATE(),
	      T.SALE_AFTR_PROD_DAY = (SELECT DATEDIFF(DAY, p.MAKE_DATE, s.SALE_DATE) FROM dbo.Product p WHERE p.CODE = s.PROD_CODE),
	      T.SALE_BEFR_EXPR_DAY = (SELECT DATEDIFF(DAY, s.SALE_DATE, p.EXPR_DATE) FROM dbo.Product p WHERE p.CODE = s.PROD_CODE);
   
   COMMIT TRANSACTION [T_CG$AINS_PDCS];
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T_CG$AINS_PDCS];
   END CATCH;
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
CREATE TRIGGER [dbo].[CG$AUPD_PDCS]
   ON  [dbo].[Payment_Detail_Commodity_Sale]
   AFTER UPDATE
AS 
BEGIN
   IF (
      SELECT COUNT(*)
        FROM dbo.Payment_Detail_Commodity_Sale t, Inserted s
       WHERE t.PYDT_CODE = s.PYDT_CODE 
         AND s.PROD_CODE = s.PROD_CODE
   ) > 1
   BEGIN
      RAISERROR(N'این کالا قبلا در ردیف فروش قرار گرفته است', 16, 1);
      RETURN;
   END
   
   
	MERGE dbo.Payment_Detail_Commodity_Sale T
	USING (SELECT * FROM Inserted) S
	ON (t.CODE = s.CODE)
	WHEN MATCHED THEN
	   UPDATE SET
	      T.MDFY_BY = UPPER(SUSER_NAME()),
	      T.MDFY_DATE = GETDATE(),
	      T.SALE_AFTR_PROD_DAY = (SELECT DATEDIFF(DAY, p.MAKE_DATE, s.SALE_DATE) FROM dbo.Product p WHERE p.CODE = s.PROD_CODE),
	      T.SALE_BEFR_EXPR_DAY = (SELECT DATEDIFF(DAY, s.SALE_DATE, p.EXPR_DATE) FROM dbo.Product p WHERE p.CODE = s.PROD_CODE);
END
GO
ALTER TABLE [dbo].[Payment_Detail_Commodity_Sale] ADD CONSTRAINT [PK_PDCS] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Payment_Detail_Commodity_Sale] ADD CONSTRAINT [FK_PDCS_PROD] FOREIGN KEY ([PROD_CODE]) REFERENCES [dbo].[Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Payment_Detail_Commodity_Sale] ADD CONSTRAINT [FK_PDCS_PYDT] FOREIGN KEY ([PYDT_CODE]) REFERENCES [dbo].[Payment_Detail] ([CODE]) ON DELETE CASCADE
GO
