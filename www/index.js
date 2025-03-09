import * as wasm from "wasm-game-of-life";

function downloadURL (data, fileName) {
  var a;
  a = document.createElement('a');
  a.href = data;
  a.download = fileName;
  document.body.appendChild(a);
  a.style = 'display: none';
  a.click();
  a.remove();
};

function downloadBlob (data, fileName, mimeType) {
  var blob, url;
  blob = new Blob([data], {
    type: mimeType
  });
  url = window.URL.createObjectURL(blob);
  downloadURL(url, fileName);
  setTimeout(function() {
    return window.URL.revokeObjectURL(url);
  }, 1000);
};

window.makePDF = (event) => {
	event.preventDefault()
	event.stopPropagation()

	let data = Object.fromEntries(new FormData(event.target).entries())
	let got = wasm.create(data).payload

  let name = 'Battery.pdf'
  if (data.arrows) name = 'Arrows.pdf'
  if (data.title) name = `${data.title}.pdf`

	downloadBlob(got, name, 'application/octet-stream');
}

window.makeBalanceLog = (event) => {
	event.preventDefault()
	event.stopPropagation()

	let data = Object.fromEntries(new FormData(event.target).entries())
	let got = wasm.create_balance_log(data).payload

  let name = 'Balance_log.pdf'

	downloadBlob(got, name, 'application/octet-stream');
}

window.makeBalanceDetail = (event) => {
	event.preventDefault()
	event.stopPropagation()

	let data = Object.fromEntries(new FormData(event.target).entries())
	let got = wasm.create_balance_detail(data).payload

  let name = 'Balance_detail.pdf'

	downloadBlob(got, name, 'application/octet-stream');
}

window.make123 = (event) => {
	event.preventDefault()
	event.stopPropagation()

	let data = Object.fromEntries(new FormData(event.target).entries())
	let got = wasm.create_123(data).payload

  let name = '123.pdf'
  if (data.title) name = `${data.title}-123.pdf`

	downloadBlob(got, name, 'application/octet-stream');
}
