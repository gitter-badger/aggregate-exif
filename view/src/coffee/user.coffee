$(document).ready ->
  params = fromURLParameter(location.search.slice(1))
  id = params.userId
  fetch("/api/user/#{id}/focal")
    .then (res) -> res.json()
    .then (json) -> renderFocalGraph(json)
  fetch("/api/user/#{id}/iso")
    .then (res) -> res.json()
    .then (json) -> renderISOGraph(json)
  fetch("/api/user/#{id}/f_number")
    .then (res) -> res.json()
    .then (json) -> renderFNumberGraph(json)
  fetch("/api/user/#{id}/exposure")
    .then (res) -> res.json()
    .then (json) -> renderExposureGraph(json)
  fetch("/api/user/#{id}/camera")
    .then (res) -> res.json()
    .then (json) -> renderCameraGraph(json)
  fetch("/api/user/#{id}/lens")
    .then (res) -> res.json()
    .then (json) -> renderLensGraph(json)

focalGroup = [10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 150, 200, 250, 300, 400, 500, 600, 800, 1000, 1500, 2000]
renderFocalGraph = (elems) ->
  ctx = getCtx('focalChart')
  _elems = _.chain(focalGroup).zip(_.tail(focalGroup))
    .map (xs) ->
      targets = _.filter elems, (elem) -> xs[0] <= elem['focal'] && elem['focal'] < xs[1]
      count = _.sumBy targets, (x) -> x['count']
      {focal: xs[0], count: count}
    .dropWhile (x) -> x['count'] == 0
    .dropRightWhile (x) -> x['count'] == 0
    .value()
  labels = _elems.map (elem) -> elem['focal']
  values = _elems.map (elem) -> elem['count']
  color = labels.map (focal) ->
    v = Math.round(gradient(Math.log2(20), Math.log2(600), 192, 0, Math.log2(focal)))
    "rgba(#{v}, #{v}, #{v}, 0.8)"
  new Chart ctx, {
    type: 'bar'
    data:
      labels: labels
      datasets: [{
        label: 'image counts'
        data: values
        backgroundColor: color
      }]
    options: _.merge(barOptions('Focal count (35mm equivalent)'), xScaleLabel('mm'))
  }

renderISOGraph = (elems) ->
  ctx = getCtx('isoChart')
  elemGroup = _.groupBy elems, (elem) ->
    Math.floor(Math.log2(elem['iso'] / 100))
  elems = _.map elemGroup, (xs) ->
    {iso: xs[0]['iso'], count: _.sumBy xs, (x) -> x['count']}
  labels = elems.map (elem) -> elem['iso']
  values = elems.map (elem) -> elem['count']
  color = labels.map (iso) ->
    v = Math.round(gradient(2, Math.log2(64), 192, 0, Math.log2(iso / 100)))
    "rgba(#{v}, #{v}, #{v}, 0.8)"
  new Chart ctx, {
    type: 'bar'
    data:
      labels: labels
      datasets: [{
        label: 'image counts'
        data: values
        backgroundColor: color
      }]
    options: barOptions('ISO count')
  }

fNumberGroup = [0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 7, 8, 9, 10, 12, 14, 16, 18, 20, 25, 30]
renderFNumberGraph = (elems) ->
  ctx = getCtx('fNumberChart')
  _elems = _.chain(fNumberGroup).zip(_.tail(fNumberGroup))
    .map (xs) ->
      targets = _.filter elems, (elem) -> xs[0] <= elem['fNumber'] && elem['fNumber'] < xs[1]
      count = _.sumBy targets, (x) -> x['count']
      {fNumber: xs[0], count: count}
    .dropWhile (x) -> x['count'] == 0
    .dropRightWhile (x) -> x['count'] == 0
    .value()
  console.log(_elems)
  labels = _elems.map (elem) -> elem['fNumber']
  values = _elems.map (elem) -> elem['count']
  color = labels.map (fNumber) ->
    v = Math.round(gradient(Math.log2(1), Math.log2(10), 192, 0, Math.log2(fNumber)))
    "rgba(#{v}, #{v}, #{v}, 0.8)"
  new Chart ctx, {
    type: 'bar'
    data:
      labels: labels
      datasets: [{
        label: 'image counts'
        data: values
        backgroundColor: color
      }]
    options: barOptions('F-Number count')
  }

exposureGroup = [-30, -15, -8, -4, -2, 1, 2, 4, 8, 15, 30, 60, 125, 250, 500, 1000, 2000, 4000, 8000, 16000].reverse()
renderExposureGraph = (elems) ->
  ctx = getCtx('exposureChart')
  elemGroup = _.groupBy elems, (elem) ->
    _.find exposureGroup, (x) -> x <= elem['exposure']
  elems = _.map elemGroup, (xs) ->
    {exposure: xs[0]['exposure'], count: _.sumBy xs, (x) -> x['count']}
  labels = elems.map (elem) -> elem['exposure']
  values = elems.map (elem) -> elem['count']
  color = labels.map (exposure) ->
    v = Math.round(gradient(1, Math.sqrt(4000), 0, 192, Math.sqrt(exposure)))
    "rgba(#{v}, #{v}, #{v}, 0.8)"
  new Chart ctx, {
    type: 'bar'
    data:
      labels: labels
      datasets: [{
        label: 'image counts'
        data: values
        backgroundColor: color
      }]
    options: barOptions('Shutter speed count')
  }

renderCameraGraph = (elems) ->
  ctx = getCtx('cameraChart')
  values = elems.map (elem) -> elem['count']
  labels = elems.map (elem) -> elem['camera']
  new Chart ctx, {
    type: 'pie'
    data:
      labels: labels
      datasets: [{
        data: values
        backgroundColor: colorSet(0.5)
      }]
  }

renderLensGraph = (elems) ->
  ctx = getCtx('lensChart')
  values = elems.map (elem) -> elem['count']
  labels = elems.map (elem) -> elem['lens']
  new Chart ctx, {
    type: 'pie'
    data:
      labels: labels
      datasets: [{
        data: values
        backgroundColor: colorSet(0.5)
      }]
  }

colorSet = (a) -> [
  "rgba(0, 65, 255, #{a})",
  "rgba(255, 40, 0, #{a})",
  "rgba(53, 161, 107, #{a})",
  "rgba(250, 245, 0, #{a})",
  "rgba(102, 204, 255, #{a})"
]

getCtx = (id) -> document.getElementById(id).getContext('2d')

gradient = (min, max, minValue, maxValue, input) ->
  v = Math.max(min, Math.min(max, input))
  rate = (v - min)/(max - min)
  (maxValue - minValue) * rate + minValue

barOptions = (title) ->
  legend:
    display: false
  title:
    display: true
    text: title
    fontSize: 18

logarithmicOptions = ->
  scales:
    xAxes: [{
      type: 'logarithmic',
      ticks:
        callback: Chart.Ticks.formatters.linear
    }]

xScaleLabel = (label) ->
  scales:
    xAxes: [{
      scaleLabel:
        display: true
        labelString: label
    }]
