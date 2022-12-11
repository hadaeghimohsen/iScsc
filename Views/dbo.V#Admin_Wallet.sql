SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*CREATE VIEW V#Transaction_Fee AS 
SELECT * FROM iRoboTech.dbo.V#Transaction_Fee WHERE TXFE_TYPE IN ('001', '009');*/
CREATE VIEW [dbo].[V#Admin_Wallet]
AS
SELECT     SRBT_SERV_FILE_NO, SRBT_ROBO_RBID, CODE, CHAT_ID, WLET_TYPE, AMNT_DNRM, LAST_IN_AMNT_DNRM, LAST_IN_DATE_DNRM, LAST_OUT_AMNT_DNRM, LAST_OUT_DATE_DNRM, 
                      TEMP_AMNT_USE, CRET_BY, CRET_DATE, MDFY_BY, MDFY_DATE
FROM         iRoboTech.dbo.Wallet
WHERE     (CHAT_ID IN
                          (SELECT     TOP (1) sr.CHAT_ID
                            FROM          iRoboTech.dbo.Service_Robot AS sr INNER JOIN
                                                   iRoboTech.dbo.Service_Robot_Group AS srg ON sr.SERV_FILE_NO = srg.SRBT_SERV_FILE_NO AND sr.ROBO_RBID = srg.SRBT_ROBO_RBID INNER JOIN
                                                   iRoboTech.dbo.[Group] AS g ON srg.GROP_GPID = g.GPID
                            WHERE      (sr.ROBO_RBID = 401) AND (srg.STAT = '002') AND (g.STAT = '002') AND (g.ADMN_ORGN = '002') AND (g.GPID = 131))) AND (SRBT_ROBO_RBID = 401)
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Wallet (iRoboTech.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 126
               Right = 247
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'V#Admin_Wallet', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'V#Admin_Wallet', NULL, NULL
GO
