import React from 'react';
import Head from 'next/head';

export default function PrivacyPolicyPage() {
  return (
    <div style={styles.container}>
      <Head>
        <title>隐私政策 - Rêverie</title>
        <meta name="description" content="Rêverie 隐私政策" />
      </Head>

      <header style={styles.header}>
        <a href="/" style={styles.backLink}>← 返回首页</a>
        <h1 style={styles.title}>隐私政策</h1>
        <p style={styles.lastUpdated}>最后更新日期: 2024年8月10日</p>
      </header>

      <main style={styles.main}>
        <div style={styles.content}>
          <div style={styles.section}>
            <p style={styles.intro}>
              本隐私政策说明了 Rêverie（以下简称"我们"、"我们的"）如何收集、使用、存储和保护用户（以下简称"您"）的信息。我们承诺保护您的隐私和个人信息安全。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>1. 信息收集</h2>
            <p style={styles.text}>
              Rêverie 尊重您的隐私，我们采取以下方式处理您的信息：
            </p>
            <ul style={styles.list}>
              <li style={styles.listItem}>
                <strong>本地处理：</strong>所有视频处理都在您的设备本地完成，我们不会将您的视频上传到服务器。
              </li>
              <li style={styles.listItem}>
                <strong>相册访问：</strong>应用需要访问您的相册以导入视频和保存处理结果。这些视频仅存储在您的设备本地。
              </li>
              <li style={styles.listItem}>
                <strong>匿名分析：</strong>我们可能会收集匿名的使用统计数据以改进应用功能，这些数据不会包含任何个人身份信息。
              </li>
            </ul>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>2. 信息使用</h2>
            <p style={styles.text}>
              我们收集的信息仅用于以下目的：
            </p>
            <ul style={styles.list}>
              <li style={styles.listItem}>提供视频处理功能</li>
              <li style={styles.listItem}>改进应用性能和用户体验</li>
              <li style={styles.listItem}>解决技术问题</li>
              <li style={styles.listItem}>发送应用更新通知（如您选择接收）</li>
            </ul>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>3. 数据存储与安全</h2>
            <p style={styles.text}>
              <strong>本地存储：</strong>您的视频文件始终存储在您的设备本地，我们不会在服务器上存储您的视频。
            </p>
            <p style={styles.text}>
              <strong>数据安全：</strong>我们采取合理的技术和组织措施保护您的信息，但请注意没有任何互联网传输或电子存储方法是100%安全的。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>4. 第三方服务</h2>
            <p style={styles.text}>
              Rêverie 不使用任何第三方分析或广告服务。我们不会与第三方分享您的个人信息。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>5. 儿童隐私</h2>
            <p style={styles.text}>
              我们的服务不面向13岁以下的儿童。我们不会有意收集13岁以下儿童的个人信息。如果发现我们收集了13岁以下儿童的信息，我们将立即删除。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>6. 隐私政策变更</h2>
            <p style={styles.text}>
              我们可能会不时更新本隐私政策。更新后的政策将在本页面发布，更新日期将反映在页面顶部。我们建议您定期查看本政策以了解任何变更。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>7. 联系我们</h2>
            <p style={styles.text}>
              如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：
            </p>
            <ul style={styles.list}>
              <li style={styles.listItem}>电子邮件：privacy@reverie-app.com</li>
              <li style={styles.listItem}>技术支持页面：<a href="/support" style={styles.link}>reverie-app.com/support</a></li>
            </ul>
          </div>

          <div style={styles.note}>
            <p>
              <strong>重要提示：</strong>本隐私政策仅适用于 Rêverie 应用。当您通过应用商店下载、安装或使用本应用时，即表示您同意本隐私政策的条款。
            </p>
          </div>
        </div>
      </main>

      <footer style={styles.footer}>
        <div style={styles.footerLinks}>
          <a href="/" style={styles.footerLink}>首页</a>
          <a href="/support" style={styles.footerLink}>技术支持</a>
          <a href="/terms" style={styles.footerLink}>使用条款</a>
        </div>
        <p style={styles.copyright}>© 2024 Rêverie. All rights reserved.</p>
      </footer>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    backgroundColor: '#000',
    color: '#fff',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
    lineHeight: '1.6',
  },
  header: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '40px 20px 20px',
    borderBottom: '1px solid #222',
  },
  backLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
    marginBottom: '20px',
    display: 'inline-block',
  },
  title: {
    fontSize: '36px',
    fontWeight: 'bold' as const,
    marginBottom: '10px',
    color: '#fff',
  },
  lastUpdated: {
    color: '#666',
    fontSize: '14px',
    marginBottom: '20px',
  },
  main: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '40px 20px',
  },
  content: {
    fontSize: '16px',
  },
  section: {
    marginBottom: '40px',
  },
  sectionTitle: {
    fontSize: '24px',
    fontWeight: 'bold' as const,
    marginBottom: '20px',
    color: '#fff',
    paddingBottom: '10px',
    borderBottom: '2px solid #333',
  },
  intro: {
    fontSize: '18px',
    color: '#aaa',
    marginBottom: '30px',
    lineHeight: '1.5',
  },
  text: {
    fontSize: '16px',
    color: '#aaa',
    marginBottom: '15px',
    lineHeight: '1.5',
  },
  list: {
    marginLeft: '20px',
    marginBottom: '20px',
  },
  listItem: {
    fontSize: '16px',
    color: '#aaa',
    marginBottom: '10px',
    lineHeight: '1.5',
  },
  link: {
    color: '#4dabf7',
    textDecoration: 'none' as const,
  },
  note: {
    backgroundColor: '#111',
    padding: '25px',
    borderRadius: '8px',
    marginTop: '40px',
    borderLeft: '4px solid #4dabf7',
  },
  footer: {
    maxWidth: '800px',
    margin: '0 auto',
    padding: '40px 20px',
    borderTop: '1px solid #222',
    textAlign: 'center' as const,
  },
  footerLinks: {
    display: 'flex',
    justifyContent: 'center',
    gap: '30px',
    marginBottom: '20px',
    flexWrap: 'wrap' as const,
  },
  footerLink: {
    color: '#888',
    textDecoration: 'none' as const,
    fontSize: '16px',
  },
  copyright: {
    color: '#666',
    fontSize: '14px',
    marginTop: '20px',
  },
};