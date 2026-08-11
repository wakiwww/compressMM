import React from 'react';
import Head from 'next/head';

export default function TermsOfUsePage() {
  return (
    <div style={styles.container}>
      <Head>
        <title>使用条款 - Rêverie</title>
        <meta name="description" content="Rêverie 使用条款" />
      </Head>

      <header style={styles.header}>
        <a href="/" style={styles.backLink}>← 返回首页</a>
        <h1 style={styles.title}>使用条款</h1>
        <p style={styles.lastUpdated}>最后更新日期: 2024年8月10日</p>
      </header>

      <main style={styles.main}>
        <div style={styles.content}>
          <div style={styles.section}>
            <p style={styles.intro}>
              欢迎使用 Rêverie（以下简称"本应用"）。请仔细阅读以下使用条款。下载、安装或使用本应用即表示您同意遵守这些条款。如果您不同意这些条款，请不要使用本应用。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>1. 应用许可</h2>
            <p style={styles.text}>
              在您遵守本条款的前提下，我们授予您个人、非独占、不可转让、有限的许可，以在您拥有或控制的设备上下载、安装和使用本应用。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>2. 使用限制</h2>
            <p style={styles.text}>您同意不：</p>
            <ul style={styles.list}>
              <li style={styles.listItem}>对本应用进行反向工程、反编译或反汇编</li>
              <li style={styles.listItem}>修改、改编或创建本应用的衍生作品</li>
              <li style={styles.listItem}>以任何形式出租、租赁、出售、再许可或转让本应用</li>
              <li style={styles.listItem}>使用本应用进行任何非法活动</li>
              <li style={styles.listItem}>使用本应用侵犯他人的知识产权或其他权利</li>
              <li style={styles.listItem}>使用本应用传播恶意软件、病毒或其他有害代码</li>
            </ul>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>3. 用户内容</h2>
            <p style={styles.text}>
              您对本应用中处理的视频内容全权负责。您声明并保证您拥有或有权使用您在本应用中处理的所有视频内容，并且这些内容不侵犯任何第三方的权利。
            </p>
            <p style={styles.text}>
              我们不会访问、存储或传输您的视频内容。所有处理都在您的设备本地完成。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>4. 知识产权</h2>
            <p style={styles.text}>
              Rêverie 应用及其所有内容（包括但不限于文本、图形、徽标、图像、软件代码）是我们的财产或我们的许可方的财产，受版权、商标和其他知识产权法保护。
            </p>
            <p style={styles.text}>
              本条款不授予您任何 Rêverie 商标、徽标或其他品牌特征的权利。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>5. 免责声明</h2>
            <p style={styles.text}>
              本应用按"原样"提供，不附带任何明示或暗示的保证，包括但不限于适销性、特定用途适用性和不侵权的保证。我们不保证本应用将满足您的要求、无中断、及时、安全或无错误。
            </p>
            <p style={styles.text}>
              我们不对因使用或无法使用本应用而引起的任何直接、间接、附带、特殊或后果性损害负责。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>6. 责任限制</h2>
            <p style={styles.text}>
              在法律允许的最大范围内，我们对您因使用本应用而产生的任何索赔的总责任不超过您为使用本应用支付的金额（如有），或 50 美元，以较高者为准。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>7. 条款变更</h2>
            <p style={styles.text}>
              我们保留随时修改这些条款的权利。更新后的条款将在本页面发布，更新日期将反映在页面顶部。您继续使用本应用即表示您接受更新后的条款。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>8. 终止</h2>
            <p style={styles.text}>
              如果您违反本条款，我们可能在不事先通知的情况下终止或暂停您使用本应用的权利。终止后，您必须停止使用本应用并删除所有副本。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>9. 适用法律</h2>
            <p style={styles.text}>
              本条款受您所在国家/地区的法律管辖，不考虑其法律冲突条款。
            </p>
          </div>

          <div style={styles.section}>
            <h2 style={styles.sectionTitle}>10. 联系我们</h2>
            <p style={styles.text}>
              如果您对本使用条款有任何疑问，请通过以下方式联系我们：
            </p>
            <ul style={styles.list}>
              <li style={styles.listItem}>电子邮件：legal@reverie-app.com</li>
              <li style={styles.listItem}>技术支持页面：<a href="/support" style={styles.link}>reverie-app.com/support</a></li>
            </ul>
          </div>

          <div style={styles.note}>
            <p>
              <strong>重要提示：</strong>在使用 Rêverie 应用前，请确保您已阅读、理解并同意这些使用条款。如果您不同意这些条款，请不要使用本应用。
            </p>
          </div>
        </div>
      </main>

      <footer style={styles.footer}>
        <div style={styles.footerLinks}>
          <a href="/" style={styles.footerLink}>首页</a>
          <a href="/support" style={styles.footerLink}>技术支持</a>
          <a href="/privacy" style={styles.footerLink}>隐私政策</a>
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