/* eslint-disable no-useless-concat */
/* eslint-disable no-return-await */
/* eslint-disable no-unused-vars */
/* eslint-disable no-floating-decimal */
/* eslint-disable no-undef */
/* eslint-disable no-console */
import { LightningElement, api, track  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import chartjs  from '@salesforce/resourceUrl/ChartJS';
import chartjscss  from '@salesforce/resourceUrl/ChartJScss';
import { loadScript,loadStyle } from 'lightning/platformResourceLoader';
const generateRandomNumber = () => {
    return Math.round(Math.random() * 100);
};
export default class IAFC_RSG_AMS_LeaderBoard extends LightningElement { 

    @api mode = "career";
    @api title;
    board = [];
    @api debug; 
    chart; 
     
    connectedCallback () {  
        Promise.all([ 
            loadScript(this, chartjs),
            loadStyle(this, chartjscss)
        ]).then(() => { 
            this.initChart();     
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading Charts',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
    }

    config = {
        type: 'horizontalBar',
        data: {
            datasets: [
                {
                    barThickness: 'flex',
                    data: [
                        // generateRandomNumber(),
                        // generateRandomNumber(),
                        // generateRandomNumber(),
                        // generateRandomNumber(),
                        // generateRandomNumber()
                    ],
                    backgroundColor: [
                        'rgba(255, 99, 132,0.7)',
                        'rgba(255, 159, 64,0.7)',
                        'rgba(255, 205, 86,0.7)',
                        'rgba(75, 192, 192,0.7)',
                        'rgba(54, 162, 235,0.7)'
                    ]
                    //,label: 'Dataset 1'
                }
            ],
            labels: ['Red', 'Orange', 'Yellow', 'Green', 'Blue']
        },
        options: {
            responsive: true,
            legend: {
                display:false
                // position: 'right',
                // labels: {
                //     generateLabels: (x)=>{
                //         console.log(x);
                //         return x.data.labels.map(function(item, index){
                //             return {
                //                 text: item.substring(0,45) + '...',
                //                 fillStyle: x.data.datasets[0].backgroundColor[index]
                //             };
                //         });
                //     }
                // }
            },
            animation: {
                animateScale: true,
                animateRotate: true 
            },
            scales: {
                yAxes: [
                    {
                        ticks:  {
                            mirror: true,
                            z:9999,
                            padding: -4,
                            fontColor: "#000"
                            }
                        ,scaleLabel: {
                            display:true,
                            labelString: 'Organization'
                        }
                        
                    }
                ],
                xAxes: [
                    {
                        scaleLabel: {
                            display:true,
                            labelString: 'RSG Hours Reported'
                        }
                    }
                ]
            },
            title: {
                display:false 
            },
            tooltips:{
                callbacks: {
                    label: function(tooltipItem, data) {
                        console.log(tooltipItem); 
                        console.log(data); 
                         
                        return 'Hours: ' +tooltipItem.xLabel;
                    }
                }
            }
        }
    };

    async getData(){
        const calloutURI = 'https://www.iafcams.org/components/api.cfc?method=gettop5';
        return fetch(calloutURI, {
            'method': 'GET'
        })
        .then((response)=>response.json())
        .then((txt)=>{ 
            return txt[this.mode].DATA.map(function (item) {
                return { 
                    id: item[0], 
                    name: item[1],
                    city: item[2],
                    state: item[3],
                    hours: item[4]
                }
            });  
        }); 
    }

    async initChart(){  
        
        if(this.title){
            this.config.options.title.text = this.title;
            this.config.options.title.display = true;
        } 


        this.board = await this.getData(); 
        this.config.data.labels = this.board.map(function (item) {
            return item.name;
        });
        this.config.data.datasets[0].data = this.board.map(function (item) {
            return item.hours;
        }); 
        //console.log(JSON.stringify(this.config)); 
        window.Chart.platform.disableCSSInjection = true;
        const canvas = document.createElement('canvas');
        this.template.querySelector('div.myChart').appendChild(canvas);
        const ctx = canvas.getContext('2d'); 
        this.chart = new window.Chart(ctx, this.config);  
        
    }
 
}