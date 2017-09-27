SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_ATTN_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   /*
      <Process>
         <Attendance code="" type="" />
      </Process>
   */
   BEGIN TRY
   BEGIN TRAN UPD_ATTN_P_T
   
   DECLARE @Code BIGINT
          ,@Type VARCHAR(3);
   
   SELECT @Code = @X.query('//Attendance').value('(Attendance/@code)[1]'    , 'BIGINT')
         ,@Type = @X.query('//Attendance').value('(Attendance/@type)[1]'    , 'VARCHAR(3)');
   
   IF @type = '001' -- ابطال و بازگشت جلسه هنرجو
   BEGIN
      DECLARE @AP BIT
             ,@AccessString VARCHAR(250);
      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>202</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 202 سطوح امینتی', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END

      UPDATE dbo.Attendance
         SET ATTN_STAT = '001'
       WHERE CODE = @Code
         AND ATTN_STAT = '002';
   END
   
   COMMIT TRAN UPD_ATTN_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(max);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN UPD_ATTN_P_T;
   END CATCH;   
END
GO
