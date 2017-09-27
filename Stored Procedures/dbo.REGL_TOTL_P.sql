SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[REGL_TOTL_P]
	@X XML
AS
BEGIN
	BEGIN TRY
	   BEGIN TRAN REGL_TOTL_P_T;
	      DECLARE @Type VARCHAR(3);
	      SELECT @Type = @X.query('Config').value('(Config/@type)[1]', 'VARCHAR(3)');
	      
	      DECLARE @ExtpCode BIGINT
	             ,@RqrqCode BIGINT
	             ,@EpitCode BIGINT
	             ,@ExtpDesc NVARCHAR(250);
	      
	      IF @Type = '001'
	      BEGIN
	         DECLARE C$Del_Expense_Type CURSOR FOR
			      SELECT rx.query('Expense_Type').value('(Expense_Type/@code)[1]', 'BIGINT')
		           FROM @X.nodes('//Delete') Dcb(rx);
   		   
		      -------------------------- Delete Expense_Type_Method
		      OPEN C$Del_Expense_Type;
		      FNFC$Del_Expense_Type:
		      FETCH NEXT FROM C$Del_Expense_Type INTO @ExtpCode;
   		   
		      IF @@FETCH_STATUS <> 0
		         GOTO CDC$Del_Expense_Type;
   		   
   		   IF EXISTS(SELECT * FROM Payment_Detail pd, Expense E  WHERE Pd.EXPN_CODE = E.CODE AND E.EXTP_CODE = @ExtpCode)
   		   BEGIN
   		      CLOSE C$Del_Expense_Type;
		         DEALLOCATE C$Del_Expense_Type; 		      		   
		         RAISERROR(N'از این گزینه در ریز هزینه های درخواست استفاده شده. قادر به حذف آن نیستید.', 16, 1);
		         RETURN;
   		   END
   		   
		      DELETE Expense_Type WHERE CODE = @ExtpCode;
   		      
		      GOTO FNFC$Del_Expense_Type;
		      CDC$Del_Expense_Type:
		      CLOSE C$Del_Expense_Type;
		      DEALLOCATE C$Del_Expense_Type; 		   
		      ------------------------ End Delete
   		   
		      DECLARE C$Ins_Expense_Type CURSOR FOR
			      SELECT rx.query('Expense_Type').value('(Expense_Type/@rqrqcode)[1]', 'BIGINT')
			            ,rx.query('Expense_Type').value('(Expense_Type/@epitcode)[1]', 'BIGINT')
		           FROM @X.nodes('//Insert') Dcb(rx);
   		          
		      -------------------------- Insert Expense_Type_Method
		      OPEN C$Ins_Expense_Type;
		      FNFC$Ins_Expense_Type:
		      FETCH NEXT FROM C$Ins_Expense_Type INTO @RqrqCode, @EpitCode;
   		   
		      IF @@FETCH_STATUS <> 0
		         GOTO CDC$Ins_Expense_Type;
   		   
		      INSERT INTO Expense_Type (RQRQ_CODE, EPIT_CODE, CODE)
		      VALUES           (@RqrqCode, @EpitCode, dbo.GNRT_NVID_U());
   		      
		      GOTO FNFC$Ins_Expense_Type;
		      CDC$Ins_Expense_Type:
		      CLOSE C$Ins_Expense_Type;
		      DEALLOCATE C$Ins_Expense_Type; 
		      ------------------------ End Insert
		      DECLARE C$Upd_Expense_Type CURSOR FOR
			      SELECT rx.query('Expense_Type').value('(Expense_Type/@code)[1]', 'BIGINT')
			            ,rx.query('Expense_Type').value('(Expense_Type/@extpdesc)[1]', 'NVARCHAR(250)')
		           FROM @X.nodes('//Update') Dcb(rx);
   		   

		      -------------------------- Insert Expense_Type_Method
		      OPEN C$Upd_Expense_Type;
		      FNFC$Upd_Expense_Type:
		      FETCH NEXT FROM C$Upd_Expense_Type INTO @ExtpCode, @ExtpDesc;
   		   
		      IF @@FETCH_STATUS <> 0
		         GOTO CDC$Upd_Expense_Type;
   		   
		      UPDATE Expense_Type
		         SET EXTP_DESC = @ExtpDesc
		       WHERE CODE = @ExtpCode;
   		      
		      GOTO FNFC$Upd_Expense_Type;
		      CDC$Upd_Expense_Type:
		      CLOSE C$Upd_Expense_Type;
		      DEALLOCATE C$Upd_Expense_Type; 
		   END
	   COMMIT TRAN REGL_TOTL_P_T;
	END TRY
	BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN REGL_TOTL_P_T;
	END CATCH
END
GO
