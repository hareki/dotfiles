api.unmapAllExcept(['d','u','C','i','v','f','cf'], /.*/);
api.map('<PageUp>','u');
api.map('<PageDown>','d');
api.map('mf', 'cf');
api.map('F', 'C')

const hintsCss =
  `
    font-size: 13px;
    font-family: 'Maple Mono NF', 'Cascadia Code', 'Helvetica Neue', Helvetica,
    Arial, sans-serif;
    color: #e0def4 !important;
    background: #1e1e2e;
    background-color: #1e1e2e;
    border: 2px solid #e0def4 !important;
    border-radius: 4px;
    padding-inline: 3px;
    min-width: 12px;
    text-align: center; 
  `;

api.Hints.style(hintsCss);
api.Hints.style(hintsCss, "text");

settings.theme = `
  .sk_theme {
    background: #1e1e2e;
    color: #e0def4;
  }
  .sk_theme input {
    color: #e0def4;
  }
  .sk_theme .url {
    color: #c4a7e7;
  }
  .sk_theme .annotation {
    color: #ebbcba;
  }
  .sk_theme kbd {
    background: #26233a;
    color: #e0def4;
  }
  .sk_theme .frame {
    background: #1f1d2e;
  }
  .sk_theme .omnibar_highlight {
    color: #403d52;
  }
  .sk_theme .omnibar_folder {
    color: #e0def4;
  }
  .sk_theme .omnibar_timestamp {
    color: #9ccfd8;
  }
  .sk_theme .omnibar_visitcount {
    color: #9ccfd8;
  }
  .sk_theme .prompt, .sk_theme .resultPage {
    color: #e0def4;
  }
  .sk_theme .feature_name {
    color: #e0def4;
  }
  .sk_theme .separator {
    color: #1e1e2e;
  }
  body {
    margin: 0;

    font-family: "Maple Mono NF", "Cascadia Code", "Helvetica Neue", Helvetica, Arial, sans-serif;
    font-size: 12px;
  }
  .sk_theme div.table {
    display: table;
  }
  .sk_theme div.table>* {
    vertical-align: middle;
    display: table-cell;
  }
  #sk_status {
    position: fixed;
    right: 20%;
    z-index: 2147483000;
    padding: 4px 8px;
    border-radius: 4px 4px 0px 0px;
    border: 1px solid #e0def4;

    bottom: 6px;
    font-weight: bold;
    font-size: 14px;
    border-width: 2px;
    border-radius: 6px;
  }
  #sk_status>span {
    line-height: 16px;
  }
  #sk_keystroke {
    padding: 6px;
    position: fixed;
    float: right;
    bottom: 0px;
    z-index: 2147483000;
    right: 0px;
    background: #1e1e2e;
    color: #e0def4;
  }
  #sk_banner {
    padding: 0.5rem;
    position: fixed;
    left: 50%;
    transform: translate(-50%, 30%);
    z-index: 2147483000;
    width: fit-content;
    font-size: 14px;
    font-weight: bold;
    color: #e0def4;
    border-radius: 4px;
    border: 2px solid #e0def4;
    text-align: center;
    background: #1e1e2e;
    white-space: nowrap;
    text-overflow: ellipsis;
    overflow: hidden;
  }
`;
