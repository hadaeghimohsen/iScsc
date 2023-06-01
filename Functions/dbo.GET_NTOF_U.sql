SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_NTOF_U]
(
	@Numb BIGINT
)
RETURNS NVARCHAR(100)
AS
BEGIN
   IF @Numb IS NULL RETURN '0';
	RETURN REPLACE( CONVERT(NVARCHAR, CONVERT(MONEY, @Numb), 1), '.00', '');
END
GO
