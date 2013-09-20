(function (global, exports, perf) {
  'use strict';

  function fixSetTarget(param) {
    if (!param)	// if NYI, just return
      return;
    if (!param.setTargetAtTime)
      param.setTargetAtTime = param.setTargetValueAtTime; 
  }

  if (window.hasOwnProperty('webkitAudioContext') && 
      !window.hasOwnProperty('AudioContext')) {
    window.AudioContext = webkitAudioContext;

    if (!AudioContext.prototype.hasOwnProperty('createGain'))
      AudioContext.prototype.createGain = AudioContext.prototype.createGainNode;
    if (!AudioContext.prototype.hasOwnProperty('createDelay'))
      AudioContext.prototype.createDelay = AudioContext.prototype.createDelayNode;
    if (!AudioContext.prototype.hasOwnProperty('createScriptProcessor'))
      AudioContext.prototype.createScriptProcessor = AudioContext.prototype.createJavaScriptNode;

    if (AudioContext.prototype.hasOwnProperty( 'createOscillator' )) {
      AudioContext.prototype.internal_createOscillator = AudioContext.prototype.createOscillator;
      AudioContext.prototype.createOscillator = function() { 
        var node = this.internal_createOscillator();
        if (!node.start)
          node.start = node.noteOn; 
        if (!node.stop)
          node.stop = node.noteOff;
        return node;
      };
    }
  }
}(window));

(function() {
    window.Wafex = {};
    var c,m,n;
    var running = [];
    Wafex.presets = {
      pew: function() {
        var o = c.createOscillator();
        var g = c.createGain();
        var start = typeof(time) === 'undefined' ? c.currentTime : time
        var end = start + 0.2;
        o.connect(g);
        g.connect(m);
        g.gain.setValueAtTime(1, start);
        g.gain.setValueAtTime(1, start + 0.15);
        g.gain.linearRampToValueAtTime(0, end);
        o.frequency.setValueAtTime(3000 + 2000 * Math.random(), start);
        o.frequency.exponentialRampToValueAtTime(500, end);
        o.start(start);
        o.stop(end);
      },
      boom: function() {
        var o = c.createBufferSource();
        var g = c.createGain();
        var start = typeof(time) === 'undefined' ? c.currentTime : time
        var end = start + 0.8;
        o.buffer = n;
        o.playbackRate.value = 0.05 + (Math.random() * 0.1);
        o.loop = true;
        o.loopEnd = n.duration;
        o.connect(g);
        g.connect(m);
        g.gain.setValueAtTime(0, start);
        g.gain.linearRampToValueAtTime(1, start + 0.01);
        g.gain.setValueAtTime(1, start + 0.2);
        g.gain.linearRampToValueAtTime(0, end);
        o.start(start);
        o.stop(end);
        
      },
      wroom: {
        start: function(time) {
          var o = c.createBufferSource();
          var b = c.createOscillator();        
          var g = c.createGain();  
          var start = typeof(time) === 'undefined' ? c.currentTime : time      
          b.type = "triangle"
          b.frequency.value = 50;
      
          o.buffer = n;
          o.playbackRate.value = 0.05 + Math.random() * 0.005;
          o.loop = true;
          o.loopEnd = n.duration;
          o.connect(g); 
          b.connect(g);
          g.connect(m);
      
          g.gain.setValueAtTime(0, start);
          g.gain.linearRampToValueAtTime(1, start + 0.01);
          o.start(start);b.start(start);
          running.push(function(time) {
            
            g.gain.setValueAtTime(1, time);
            g.gain.linearRampToValueAtTime(0, time + 0.3);
            o.stop(time + 0.4); b.stop(time + 0.4);
          });
        
        },
        stop: function(time) {
          
          time = typeof(time) === 'undefined' ? c.currentTime : time      
          
          var t = running.shift()
          if (t) t(time);
        }
        
      }
    }
      
    Wafex.init = function() {
      var i,l;
      var I = Wafex;      
      c = new AudioContext();
      
      n = c.createBuffer(1, 22050 * 2, 22050);
      var array = n.getChannelData(0);
      for(i=0,l=array.length;i<l;i++) {
        array[i] = Math.random() * 2 - 1;
      }
      
      m = c.createGain();
      m.gain.value = 0.8;
      m.connect(c.destination);
      Wafex.volume = m.gain;
    }
    Wafex.play = function(preset, time, options) {
      Wafex.presets[preset](time, options);
    }
    Wafex.start = function(preset, time, options) {
      Wafex.presets[preset].start(time, options);
    }
    Wafex.stop = function(preset, time, options) {
      Wafex.presets[preset].stop(time);
    }
    
})();
