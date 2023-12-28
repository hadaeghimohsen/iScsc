SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_FIGH_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION T$DEL_FIGH_P
	   DECLARE @AP BIT
             ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>254</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 254 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END
      
      -- Local Param
      DECLARE @FileNo BIGINT = @X.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');
      
      INSERT INTO dbo.Log_Operation ( LOID ,LOG_TYPE ,LOG_TEXT )
      SELECT 0, '009', (
         SELECT N'حذف کامل اطلاعات پرونده ' + f.NAME_DNRM + N' به شماره تلفن ' + ISNULL(f.CELL_PHON_DNRM, N'بدون شماره موبایل') + N' در تاریخ ' + dbo.GET_MTOS_U(GETDATE()) + N' توسط کاربر ' + SUSER_NAME() + N' از سیستم به صورت کامل حذف شد'
           FROM dbo.Fighter f
          WHERE f.FILE_NO = @FileNo
      );
      
      DELETE Aggregation_Operation_Detail WHERE FIGH_FILE_NO = @fileno;
      DELETE dbo.Payment_Discount WHERE FIGH_FILE_NO_DNRM = @FileNo;
      DELETE Payment_Method WHERE FIGH_FILE_NO_DNRM = @fileno;
      DELETE dbo.Payment_Expense WHERE PYDT_CODE IN (SELECT pd.CODE FROM dbo.Payment_Detail pd WHERE pd.PYMT_RQST_RQID IN (SELECT rr.RQST_RQID FROM dbo.Request_Row rr WHERE rr.FIGH_FILE_NO = @FileNo));
      DELETE Gain_Loss_Rial WHERE FIGH_FILE_NO = @fileno;
      DELETE Payment_Detail WHERE PYMT_RQST_RQID in (SELECT RQST_RQID FROM Request_Row rr WHERE FIGH_FILE_NO = @fileno);
      DELETE dbo.Dresser_Attendance WHERE FIGH_FILE_NO = @FileNo;
      DELETE dbo.Attendance WHERE FIGH_FILE_NO = @FileNo;
      DELETE dbo.Member_Ship WHERE FIGH_FILE_NO = @FileNo;
      DELETE Request_Row WHERE FIGH_FILE_NO = @fileno;
      UPDATE dbo.Fighter_Public SET REF_CODE = NULL WHERE REF_CODE = @FileNo;
      DELETE Fighter WHERE file_no = @fileno;
      
	COMMIT TRANSACTION [T$DEL_FIGH_P]
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRANSACTION [T$DEL_FIGH_P]
	END CATCH	
END
GO
