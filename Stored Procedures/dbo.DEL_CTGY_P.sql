SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_CTGY_P]
	-- Add the parameters for the stored procedure here
	@Code     BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
   -- پایان دسترسی
   BEGIN TRY
   BEGIN TRAN CG$ADEL_CTGY_T
      
	   DECLARE @AP BIT
	          ,@AccessString VARCHAR(250);
	   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>23</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
      EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
      IF @AP = 0 
      BEGIN
         RAISERROR ( N'خطا - عدم دسترسی به ردیف 23 سطوح امینتی : شما مجوز حذف کردن رده کمربند را ندارید', -- Message text.
                  16, -- Severity.
                  1 -- State.
                  );
         RETURN;
      END

      IF EXISTS(
         SELECT *
           FROM dbo.Fighter_Public P
          WHERE P.CTGY_CODE = @Code
      )
      BEGIN
         RAISERROR (N'برای رسته جاری اطلاعاتی در جدول اطلاعات عمومی و سوابق هنرجویان و مربیان وجود دارد که نمی توان آن را حذف کنید', 16, 1);
         RETURN;
      END 
    
    -- Insert statements for trigger here
    DELETE Category_Belt
     WHERE CODE = @Code;
   
   COMMIT TRAN CG$ADEL_CTGY_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$ADEL_CTGY_T;
   END CATCH 
   
   
END
GO
